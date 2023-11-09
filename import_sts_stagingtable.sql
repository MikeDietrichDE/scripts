-- -----------------------------------------------------------------------------------
-- File Name    : https://github.com/MikeDietrichDE/scripts/blob/main/import_sts_stagingtable.sql
-- Author       : Mike Dietrich
-- Description  : Import a SQL Tuning Set from a staging table export
-- Requirements : User TPCC needs READ, WRITE ON DIRECTORY DATA_PUMP_IMP
--                User TPCC needs IMP_FULL_DATABASE, or at least parts of it
-- Call Syntax  : @sts_staging_exp.sql
-- Last Modified: 06/11/2023
-- Database Rel.: Oracle 19c and others
-- Import Script: https://oracle-base.com/articles/misc/data-pump-api
-- -----------------------------------------------------------------------------------

SET SERVEROUT ON
COLUMN NAME FORMAT A30
COLUMN OWNER FORMAT A30


declare
  l_dp_handle       number;

begin
  -- Open a schema import job.
  l_dp_handle := dbms_datapump.open(
    operation   => 'IMPORT',
    job_mode    => 'TABLE',
    remote_link => NULL,
    job_name    => 'TESTUSER1_EMP_IMPORT',
    version     => 'LATEST');

  -- Specify the dump file name and directory object name.
  dbms_datapump.add_file(
    handle    => l_dp_handle,
    filename  => 'sts_staging_export.dmp',
    directory => 'DATA_PUMP_IMP');

  -- Specify the log file name and directory object name.
  dbms_datapump.add_file(
    handle    => l_dp_handle,
    filename  => 'sts_staging_import_LOG.log',
    directory => 'DATA_PUMP_IMP',
    filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);

  dbms_datapump.start_job(l_dp_handle);

  dbms_datapump.detach(l_dp_handle);

  dbms_output.put_line('Import of staging table TAB_STAGE1 has been finished.');
  
--
-- The following section is neceesary to avoid errors such as:
--  ORA-15705: staging table does not exist
--  ORA-19385: staging table is empty
-- This seems to be credited to the timing.
-- The commits and the 10 second sleep are only there to ensure
-- that the staging table is present and rows are seen.
--


  commit;
  dbms_session.sleep(10);
  dbms_output.put_line('Import of staging table TAB_STAGE1 has been finished.');
  commit;

--
-- Unpack the staging table
-- into a SQL Tuning Set
--

 DBMS_SQLTUNE.UNPACK_STGTAB_SQLSET (
      sqlset_name        => 'STS_CaptureCursorCache',
      sqlset_owner       => 'TPCC',
      replace            => TRUE,
      staging_table_name => 'TAB_STAGE1',
      staging_schema_owner => 'TPCC' );

  dbms_output.put_line('Staging table TAB_STAGE1 has been unpacked into STS_CaptureCursorCache.');

end;
/
