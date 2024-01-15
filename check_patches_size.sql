-- -----------------------------------------------------------------------------------
-- File Name    : https://github.com/MikeDietrichDE/scripts/blob/main/check_patches_size.sql
-- Author       : Mike Dietrich
-- Description  : Displays the space being used to store patch rollback zip files
-- Requirements : Access to the DBA role.
-- Call Syntax  : @check_patches_size.sql
-- Last Modified: 15/01/2024
-- Database Rel.: Oracle 19c
-- -----------------------------------------------------------------------------------


column patch_id format 9999999999
column ru_version format a15
column lob_size_md format 9999
COLUMN ru_build_ts FORMAT A20
COLUMN SUBSTR(description,1,40) FORMAT A40

set linesize 100
set pagesize 300

ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'MM/DD/YY HH24:MI';
ALTER SESSION SET "_EXCLUDE_SEED_CDB_VIEW" = FALSE;

SELECT
    patch_id,
    ru_version,
    TO_CHAR(ru_build_timestamp, 'MM/DD/YYYY HH24:MI:SS') AS ru_build_ts,
    round(dbms_lob.getlength(patch_directory) / 1024 / 1024) lob_size_mb
FROM
    sys.registry$sqlpatch_ru_info;

SELECT
    patch_id,
    SUBSTR(description,1,40) PATCH_DESCRIPTION,
    TO_CHAR(source_build_timestamp, 'MM/DD/YYYY HH24:MI:SS') AS patch_build_ts,
    round(dbms_lob.getlength(patch_directory) / 1024 / 1024) lob_size_mb
FROM
    sys.registry$sqlpatch
WHERE
    patch_type<>'RU';



SELECT
   con_id, round(sum(dbms_lob.getlength(patch_directory) / 1024 / 1024)) total_lob_size_mba
FROM
   containers(sys.registry$sqlpatch_ru_info)
GROUP BY
   con_id
ORDER BY
   con_id;

SELECT
   con_id, round(sum(dbms_lob.getlength(patch_directory) / 1024 / 1024)) total_lob_size_mba
FROM
   containers(sys.registry$sqlpatch)
GROUP BY
   con_id
ORDER BY
   con_id;

