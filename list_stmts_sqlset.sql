-- ---------------------------------------------------------------------------------------
-- File Name    : https://github.com/MikeDietrichDE/scripts/blob/main/list_stmts_sqlset.sql
-- Author       : Mike Dietrich
-- Description  : List the contents of a SQL Tuning Set, here: STS_CaptureCursorCache
-- Call Syntax  : @list_stmts_sqlset.sql
-- Last Modified: 12/11/2023
-- Database Rel.: Oracle 19c and others
-- Credits      : Ulrike Schwinn
--                https://blogs.oracle.com/coretec/post/oracle-sql-tuning-sets-the-basis-for-sql-tuning
-- ---------------------------------------------------------------------------------------

set linesize window
set pages 50000
set long 300000



select
  sql_id,
  executions,
  trunc(elapsed_time/1000,0) ELAPSED_IN_MS,
  trunc(cpu_time/1000,0) CPU_IN_MS,
  substr(sql_text,1,100) SQL_STATEMENT
from
  dba_sqlset_statements
where 
  sqlset_name = 'STS_CaptureCursorCache' and
  sqlset_owner = 'TPCC'
ORDER BY 3 desc;
