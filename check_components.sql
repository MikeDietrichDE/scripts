-- -----------------------------------------------------------------------------------
-- File Name    : https://MikeDietrichDE.com/wp-content/scripts/12c/check_componets.sql
-- Author       : Mike Dietrich
-- Description  : Displays installed components from DBA_REGISTRY
-- Requirements : Access to the DBA role.
-- Call Syntax  : @check_components.sql
-- Last Modified: 24/07/2017
-- -----------------------------------------------------------------------------------

set line 200
set pages 1000
col COMP_ID format a8
col COMP_NAME format a34
col SCHEMA format a12
col STATUS format a10
col VERSION format a12
col CON_ID format 99

select CON_ID, COMP_ID, comp_name, schema, status, version from CDB_REGISTRY order by 1,2;
