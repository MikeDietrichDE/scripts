-- -----------------------------------------------------------------------------------
-- File Name    : https://MikeDietrichDE.com/wp-content/scripts/12c/check_inv_objs.sql
-- Author       : Mike Dietrich
-- Description  : Shows invalid objects CDB-wide per CON_ID
-- Requirements : Access to the DBA role.
-- Call Syntax  : @check_inv_objs.sql
-- Last Modified: 24/07/2017
-- -----------------------------------------------------------------------------------

set line 200
set pages 1000
col owner format a12
col object_type format a12
col object_name format a30
col STATUS format a8
col CON_ID format 9

select con_id, owner, object_type, object_name, status from CDB_OBJECTS where status='INVALID' order by 1,2,3;