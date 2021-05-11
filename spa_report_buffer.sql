SET PAGESIZE 0
SET LINESIZE 1000
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET TRIMSPOOL ON
SET TRIM ON

set echo on
column filename new_val filename
select 'compare_spa_runs_' || to_char(sysdate, 'yyyymmddhh24miss' ) || '.html' filename from dual;

spool &filename

set echo off
set feedback off

SELECT DBMS_SQLPA.report_analysis_task(
  'UPGRADE_TO_19C_3',
  'HTML',
  'ALL',
  'ALL'
  )
FROM   dual;

SPOOL OFF
