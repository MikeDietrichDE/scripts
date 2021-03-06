-- -----------------------------------------------------------------------------------
-- File Name    : https://MikeDietrichDE.com/wp-content/scripts/12c/check_patches.sql
-- Author       : Mike Dietrich (2nd query borrowed from Tim Hall)
-- Description  : Displays contents of the patches (BP/PSU) registry and history
-- Requirements : Access to the DBA role.
-- Call Syntax  : @check_patches.sql
-- Last Modified: 13/07/2018
-- -----------------------------------------------------------------------------------

SET LINESIZE 500
SET PAGESIZE 1000
SET SERVEROUT ON
SET LONG 2000000

COLUMN action_time FORMAT A12
COLUMN action FORMAT A10
COLUMN bundle_series FORMAT A4
COLUMN comments FORMAT A30
COLUMN description FORMAT A40
COLUMN namespace FORMAT A20
COLUMN status FORMAT A10
COLUMN version FORMAT A10

spool check_patches.txt

SELECT TO_CHAR(action_time, 'YYYY-MM-DD') AS action_time,
 action,
 status,
 description,
 version,
 patch_id,
 bundle_series
 FROM   sys.dba_registry_sqlpatch
 ORDER by action_time;


spool off