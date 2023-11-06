-- -----------------------------------------------------------------------------------
-- File Name    : https://MikeDietrichDE.com/wp-content/scripts/19/spm_load_all.sql
-- Author       : Mike Dietrich
-- Description  : Load all plans from a SQL Tuning Set into SPM
-- Requirements : Access to the DBA role.
-- Call Syntax  : @spm_load_all.sql
-- Last Modified: 06/11/2023
-- Database Rel.: Oracle 19c and others
-- -----------------------------------------------------------------------------------

SET SERVEROUT ON
SET PAGESIZE 1000
SET LONG 2000000
SET LINESIZE 400


DECLARE

l_plans_loaded  PLS_INTEGER;

BEGIN

  l_plans_loaded := DBMS_SPM.load_plans_from_sqlset(
                       sqlset_name  => 'STS_CaptureCursorCache',
                       fixed        => 'YES',
                       enabled      => 'YES'
                       );

END;
/
