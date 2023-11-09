-- -----------------------------------------------------------------------------------
-- File Name    : https://github.com/MikeDietrichDE/scripts/blob/main/capture_cc.sql
-- Author       : Mike Dietrich
-- Description  : Capture SQL Statements from Cursor Cache into a SQL Tuning Set
-- Requirements : Access to the DBA role.
-- Call Syntax  : @capture_cc.sql
-- Last Modified: 29/05/2017
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

BEGIN

  SELECT count(*)
  INTO   sts_exists
  FROM   DBA_SQLSET
  WHERE  rownum = 1 AND
         name = 'STS_CaptureCursorCache';

  IF sts_exists = 1 THEN
    SYS.DBMS_SQLTUNE.DROP_SQLSET(
       sqlset_name=>'STS_CaptureCursorCache'
       );
  ELSE
    DBMS_OUTPUT.PUT_LINE('SQL Tuning Set does not exist - will be created ...');
  END IF;


--
-- Create a SQL Tuning SET 'STS_CaptureCursorCache'
--

  SYS.DBMS_SQLTUNE.CREATE_SQLSET(
     sqlset_name=>'STS_CaptureCursorCache',
     description=>'Statements from Before-Change'
     );


--
-- Poll the Cursor Cache
-- time_limit: The total amount of time, in seconds, to execute
-- repeat_interval: The amount of time, in seconds, to pause between sampling
-- Adjust both settings based on needs
--

 DBMS_OUTPUT.PUT_LINE('Now polling the cursor cache for 30 seconds every 5 seconds ...');

 DBMS_SQLTUNE.CAPTURE_CURSOR_CACHE_SQLSET(
        sqlset_name => 'STS_CaptureCursorCache',
        time_limit => 30,
        repeat_interval => 5,
        capture_option => 'MERGE',
        capture_mode => DBMS_SQLTUNE.MODE_ACCUMULATE_STATS,
        basic_filter => NULL,
        sqlset_owner => NULL,
        recursive_sql => 'HAS_RECURSIVE_SQL');

--
-- Display the amount of statements collected in the STS
--

SELECT statement_count
INTO stmt_count
FROM dba_sqlset
WHERE name = 'STS_CaptureCursorCache';

DBMS_OUTPUT.PUT_LINE('There are now ' || stmt_count || ' SQL Statements in this STS.');

--
-- If you need more details please use:
--
--    SELECT sql_text,cpu_time,elapsed_time, executions, buffer_gets
--      FROM dba_sqlset_statements
--      WHERE sqlset_name='STS_CaptureCursorCache';
--

END;
/
