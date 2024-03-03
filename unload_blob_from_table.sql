----
-- procedure adopted from:
-- https://www.codeproject.com/Questions/898270/How-I-Can-Export-Oracle-blob-Field-to-a-file-on-di
-- and adjusted to my needs.
---


CREATE DIRECTORY ZIP AS '/home/oracle/zip';

GRANT READ, WRITE ON DIRECTORY ZIP TO PUBLIC;

CREATE OR REPLACE PROCEDURE UNLOAD_ZIP (
   p_directory   IN   VARCHAR2
)
IS
   v_blob        BLOB;
   v_start       NUMBER             := 1;
   v_bytelen     NUMBER             := 2000;
   v_len         NUMBER;
   v_raw         RAW (2000);
   v_x           NUMBER;
   v_output      UTL_FILE.file_type;
   v_file_name   VARCHAR2 (200);
BEGIN

   FOR i IN (SELECT DBMS_LOB.getlength (PATCH_DIRECTORY) v_len, RU_VERSION v_file_name,
                    PATCH_DIRECTORY v_blob
               FROM SYS.REGISTRY$SQLPATCH_RU_INFO)
 
   LOOP
      v_output := UTL_FILE.fopen (p_directory, i.v_file_name || '.zip', 'wb', 32760);
      v_x := i.v_len;
      v_start := 1;
      v_bytelen := 2000;

      WHILE v_start < i.v_len AND v_bytelen > 0
      LOOP
         DBMS_LOB.READ (i.v_blob, v_bytelen, v_start, v_raw);
         UTL_FILE.put_raw (v_output, v_raw);
         UTL_FILE.fflush (v_output);
         v_start := v_start + v_bytelen;
         v_x := v_x - v_bytelen;

         IF v_x < 2000
         THEN
            v_bytelen := v_x;
         END IF;
      END LOOP;

      UTL_FILE.fclose (v_output);
   END LOOP;
END UNLOAD_ZIP;
/
   
exec unload_zip('ZIP');
