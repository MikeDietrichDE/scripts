-- -----------------------------------------------------------------------------------
-- File Name    : https://github.com/MikeDietrichDE/scripts/blob/main/export_sts_stagingtable.sql
-- Author       : Mike Dietrich
-- Description  : Pack a SQL Tuning Set into a staging table and export it
-- Requirements : User TPCC needs READ, WRITE ON DIRECTORY DATA_PUMP_DIR
--                User TPCC needs EXP_FULL_DATABASE or at least parts of it
--                The SQL Tuning Set (STS) to be exported is owned by TPCC
-- Call Syntax  : @sts_staging_exp.sql
-- Last Modified: 06/11/2023
-- Database Rel.: Oracle 19c and others
-- -----------------------------------------------------------------------------------



DECLARE

  l_dp_handle number;

BEGIN

--
-- Check if Staging Table exists
-- If it does exist, drop it
-- If it does not exist, create it
-- In 23c improved syntax using IF NOT EXISTS would shorten code
--

   EXECUTE IMMEDIATE 'DROP TABLE TPCC.TAB_STAGE1';
   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE != -942 THEN
            RAISE;
         END IF;



   DBMS_SQLTUNE.CREATE_STGTAB_SQLSET (
      table_name  => 'TAB_STAGE1',
      schema_name => 'TPCC');

   DBMS_OUTPUT.PUT_LINE('Staging table TPCC.TAB_STAGE1 has been created successfully.');


--
-- Move STS into the staging table
--

   DBMS_SQLTUNE.PACK_STGTAB_SQLSET(
    sqlset_name =>'STS_CaptureCursorCache',
    sqlset_owner=>'TPCC',
--  staging_table_owner =>'TPCC',
    staging_table_name  =>'TAB_STAGE1');

   DBMS_OUTPUT.PUT_LINE('SQL Tuning Set STS_CaptureCursorCache has been moved into staging table.');


--
-- Export the staging table into the DATA_PUMP_DIR
-- See: https://oracle-base.com/articles/misc/data-pump-api#table-export
--

  -- Open a table export job.
  l_dp_handle := dbms_datapump.open(
    operation   => 'EXPORT',
    job_mode    => 'TABLE',
    remote_link => NULL,
   job_name    => 'STS_STAGING_EXPORT',
    version     => 'LATEST');

  -- Specify the dump file name and directory object name.
    dbms_datapump.add_file(
    handle    => l_dp_handle,
    filename  => 'sts_staging_export.dmp',
    directory => 'DATA_PUMP_DIR');


  -- Specify the log file name and directory object name.
  dbms_datapump.add_file(
    handle    => l_dp_handle,
    filename  => 'sts_staging_export_LOG.log',
    directory => 'DATA_PUMP_DIR',
    filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);

  -- Specify the table to be exported, filtering the schema and table.
  dbms_datapump.metadata_filter(
    handle => l_dp_handle,
    name   => 'SCHEMA_EXPR',
    value  => '= ''TPCC''');

  dbms_datapump.metadata_filter(
    handle => l_dp_handle,
    name   => 'NAME_EXPR',
    value  => '= ''TAB_STAGE1''');

  dbms_datapump.start_job(l_dp_handle);

  dbms_datapump.detach(l_dp_handle);

END;
/
