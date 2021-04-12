-- -----------------------------------------------------------------------------------
-- File Name    : https://MikeDietrichDE.com/wp-content/scripts/12c/capture_awr.sql
-- Author       : Mike Dietrich
-- Description  : Capture SQL Statements from AWR into a SQL Tuning Set
-- Requirements : Access to the DBA role.
-- Call Syntax  : @capture_awr.sql
-- Last Modified: 31/05/2017
-- -----------------------------------------------------------------------------------

SET SERVEROUT ON
SET PAGESIZE 1000
SET LONG 2000000
SET LINESIZE 400

--
-- Drop the SQL Tuning SET if it exists
--

DECLARE

  sts_exists number;
  stmt_count number;
  cur sys_refcursor;
  begin_id   number;
  end_id     number;

BEGIN

  SELECT count(*)
  INTO   sts_exists
  FROM   DBA_SQLSET
  WHERE  rownum = 1 AND
         name = 'STS_CaptureAWR';

  IF sts_exists = 1 THEN
    SYS.DBMS_SQLTUNE.DROP_SQLSET(
       sqlset_name=>'STS_CaptureAWR'
       );
  ELSE
    DBMS_OUTPUT.PUT_LINE('SQL Tuning Set does not exist - will be created ...');
  END IF;


--
-- Create a SQL Tuning SET 'STS_CaptureCursorCache'
--

  SYS.DBMS_SQLTUNE.CREATE_SQLSET(
     sqlset_name=>'STS_CaptureAWR',
     description=>'Statements from AWR Before-Change'
     );

DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;

SELECT min(snap_id)
INTO begin_id
FROM dba_hist_snapshot;


SELECT max(snap_id)
INTO end_id
FROM dba_hist_snapshot;

DBMS_OUTPUT.PUT_LINE('Snapshot Range between ' || begin_id || ' and ' || end_id || '.');

open cur for
  select value(p) from table(dbms_sqltune.select_workload_repository(
       begin_snap       => begin_id,
       end_snap         => end_id,
       basic_filter     => 'parsing_schema_name not in (''DBSNMP'',''SYS'',''ORACLE_OCM'')',
       ranking_measure1 => 'elapsed_time',
       result_limit     => 5000)) p;
  dbms_sqltune.load_sqlset('STS_CaptureAWR', cur);
close cur;

--
-- Display the amount of statements collected in the STS
--

SELECT statement_count
INTO stmt_count
FROM dba_sqlset
WHERE name = 'STS_CaptureAWR';

DBMS_OUTPUT.PUT_LINE('There are ' || stmt_count || ' SQL Statements in STS_CaptureAWR.');
--
-- If you need more details please use:
--
--    SELECT sql_text,cpu_time,elapsed_time, executions, buffer_gets
--      FROM dba_sqlset_statements
--      WHERE sqlset_name='STS_CaptureAWR';
--

END;
/
