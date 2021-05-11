-- -----------------------------------------------------------------------------------
-- File Name    : https://MikeDietrichDE.com/wp-content/scripts/12c/run_spa.sql
-- Author       : Mike Dietrich
-- Description  : Run SQL Performance Analyzer on a SQL Tuning Set
-- Requirements : Access to the DBA role.
-- Call Syntax  : @run_spa.sql
-- Last Modified: 20/06/2018
-- -----------------------------------------------------------------------------------

SET SERVEROUT ON
SET PAGESIZE 1000
SET LONG 2000000
SET LINESIZE 400

--
-- Check if SQL Tuning SET if it exists
--

DECLARE

  sts_exists number;
  sts_task   VARCHAR2(64);
  tname      VARCHAR2(100);
  spa_exists number;

BEGIN

  SELECT count(*)
  INTO   sts_exists
  FROM   DBA_SQLSET
  WHERE  rownum = 1 AND
         name = 'STS_CaptureAWR';

  IF sts_exists <> 1 THEN
    DBMS_OUTPUT.PUT_LINE('SQL Tuning Set does not exist - creating it ...');
    SYS.DBMS_SQLTUNE.CREATE_SQLSET(
     sqlset_name=>'STS_CaptureAWR',
     description=>'Statements from AWR Before-Change'
     );
  ELSE
    DBMS_OUTPUT.PUT_LINE('SQL Tuning Set does exist - will run SPA now ...');
  END IF;


  SELECT count(*)
  INTO   spa_exists
  FROM   DBA_ADVISOR_TASKS
  WHERE  rownum = 1 AND
         task_name = 'UPGRADE_TO_19C';

  IF spa_exists = 1 THEN
    SYS.DBMS_SQLPA.DROP_ANALYSIS_TASK(
       task_name=>'UPGRADE_TO_19C'
       );
  ELSE
    DBMS_OUTPUT.PUT_LINE('SQL Performance Analyzer Task does not exist - will be created ...');
  END IF;

--
-- Create a SPA Task and parameterize it
--
 

  tname := DBMS_SQLPA.CREATE_ANALYSIS_TASK( 
            sqlset_name=>'STS_CaptureAWR', 
            task_name=>'UPGRADE_TO_19C', 
            description=>'Move to 19c');

--
-- Set Parameters for SPA Task 
--

 DBMS_SQLPA.SET_ANALYSIS_TASK_PARAMETER( 
     task_name => 'UPGRADE_TO_19C', 
     parameter => 'workload_impact_threshold', 
     value     => 2); 
 DBMS_SQLPA.SET_ANALYSIS_TASK_PARAMETER( 
     task_name => 'UPGRADE_TO_19C', 
     parameter => 'sql_impact_threshold', 
     value     => 2); 

--
-- Convert STS information from 11.2.0.4
--

  DBMS_SQLPA.EXECUTE_ANALYSIS_TASK( 
     task_name => 'UPGRADE_TO_19C', 
     execution_name => 'EXEC_SPA_TASK_11204', 
     execution_type => 'CONVERT SQLSET', 
     execution_desc => 'Convert 11204 Workload'); 

--
-- Simulate execution of STS in 19c
--

  DBMS_SQLPA.EXECUTE_ANALYSIS_TASK( 
     task_name => 'UPGRADE_TO_19C', 
     execution_name => 'EXEC_SPA_TASK_19C', 
     execution_type => 'TEST EXECUTE', 
     execution_desc => 'Test 11204 Workload in 19c'); 

--
-- Compare performance before/after on CPU_TIME
--


   DBMS_SQLPA.EXECUTE_ANALYSIS_TASK( 
     task_name => 'UPGRADE_TO_19C', 
     execution_name => 'Compare 11204 to 19c CPU_TIME', 
     execution_type => 'COMPARE PERFORMANCE', 
     execution_params => 
       DBMS_ADVISOR.ARGLIST( 
               'comparison_metric', 
               'cpu_time', 
               'execution_name1','EXEC_SPA_TASK_11204', 
               'execution_name2','EXEC_SPA_TASK_19C'), 
     execution_desc => 'Compare 11204 to 19c CPU_TIME'
     ); 


END;
/

