-- -----------------------------------------------------------------------------------
-- File Name    : https://MikeDietrichDE.com/wp-content/scripts/19/check_patchesi_19.sql
-- Author       : Mike Dietrich
-- Description  : Displays contents of the patches (BP/PSU) registry and history
-- Requirements : Access to the DBA role.
-- Call Syntax  : @check_patches_19.sql
-- Last Modified: 24/03/2020
-- Database Rel.: Oracle 19c
-- -----------------------------------------------------------------------------------

SET LINESIZE 500
SET PAGESIZE 1000
SET SERVEROUT ON
SET LONG 2000000

COLUMN action_time FORMAT A20
COLUMN action FORMAT A10
COLUMN status FORMAT A10
COLUMN description FORMAT A40
COLUMN source_version FORMAT A10
COLUMN target_version FORMAT A10


alter session set "_exclude_seed_cdb_view"=FALSE;

spool check_patches_19.txt

 select CON_ID,
        TO_CHAR(action_time, 'YYYY-MM-DD') AS action_time,
        PATCH_ID,
        PATCH_TYPE,
        ACTION,
        DESCRIPTION,
        SOURCE_VERSION,
        TARGET_VERSION
   from CDB_REGISTRY_SQLPATCH
  order by CON_ID, action_time, patch_id;

spool off
