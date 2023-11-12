

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
