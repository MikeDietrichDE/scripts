-- This query will measure the minimum SGA size for upgrades and patching
-- to Oracle AI Database 26ai Release Update 23.26.3 and newer.
-- The minimum SGA allocation algorith has been changed.
-- You may need to increase your SGA size in the target version.
-- https://mikedietrichde.com/2026/10/13/oracle-23-26-3-may-require-a-larger-sga-than-previous-releases/
--
-- Mike Dietrich -- 2026-10-12
--
-- Please use with caution - this is not an official Oracle script
--
---------------------------------------------------------------------------------------

WITH
  inst AS (
    SELECT instance_name
    FROM v$instance
  ),
  cpu AS (
    SELECT CASE
             WHEN TO_NUMBER(p.value) > 0 THEN TO_NUMBER(p.value)
             ELSE os.value
           END AS cpu_count
    FROM v$system_parameter p
    CROSS JOIN v$osstat os
    WHERE p.name = 'cpu_count'
      AND os.stat_name = 'NUM_CPUS'
  ),
  current_target AS (
    SELECT TO_NUMBER(value) AS bytes
    FROM v$system_parameter
    WHERE name = 'sga_target'
  ),
  spfile_components AS (
    SELECT LOWER(p.name) AS name,
           CASE
             WHEN REGEXP_LIKE(TRIM(p.value), '^[0-9]+$')
             THEN TO_NUMBER(TRIM(p.value))
             ELSE 0
           END AS bytes,
           ROW_NUMBER() OVER (
             PARTITION BY LOWER(p.name)
             ORDER BY CASE
                        WHEN UPPER(p.sid) =
                             UPPER(i.instance_name) THEN 1
                        ELSE 2
                      END
           ) AS rn
    FROM v$spparameter p
    CROSS JOIN inst i
    WHERE p.isspecified = 'TRUE'
      AND UPPER(p.sid) IN ('*', UPPER(i.instance_name))
      AND LOWER(p.name) IN (
        'db_cache_size',
        'shared_pool_size',
        'large_pool_size',
        'java_pool_size',
        'streams_pool_size',
        'data_transfer_cache_size',
        'vector_memory_size',
        'inmemory_size',
        'memoptimize_pool_size',
        'olap_page_pool_size',
        'db_keep_cache_size',
        'db_recycle_cache_size',
        'db_2k_cache_size',
        'db_4k_cache_size',
        'db_8k_cache_size',
        'db_16k_cache_size',
        'db_32k_cache_size',
        'log_buffer'
      )
  ),
  pool_totals AS (
    SELECT NVL(SUM(
             CASE
               WHEN name = 'db_cache_size' AND bytes > 0
               THEN bytes
               ELSE 0
             END
           ), 0) AS db_cache_bytes,
           NVL(SUM(
             CASE
               WHEN name <> 'db_cache_size' AND bytes > 0
               THEN bytes
               ELSE 0
             END
           ), 0) AS other_component_bytes,
           NVL(SUM(
             CASE WHEN bytes > 0 THEN bytes ELSE 0 END
           ), 0) AS component_bytes,
           LISTAGG(
             CASE
               WHEN bytes > 0 THEN
                 '    - ' || UPPER(name) || ': ' ||
                 TO_CHAR(
                   ROUND(bytes / 1048576, 1),
                   'FM999,999,990.0'
                 ) || ' MB'
             END,
             CHR(10)
           ) WITHIN GROUP (ORDER BY name) AS component_detail
    FROM spfile_components
    WHERE rn = 1
  ),
  spfile_status AS (
    SELECT COUNT(*) AS specified_count
    FROM v$spparameter
    WHERE isspecified = 'TRUE'
  ),
  estimate AS (
    SELECT c.cpu_count,
           t.bytes AS current_sga_target_bytes,
           GREATEST(
             c.cpu_count * 128 * 1048576,
             p.db_cache_bytes
           ) + p.other_component_bytes AS minimum_sga_bytes,
           p.component_bytes,
           NVL(
             p.component_detail,
             '    - none explicitly set'
           ) AS component_detail,
           s.specified_count
    FROM cpu c
    CROSS JOIN current_target t
    CROSS JOIN pool_totals p
    CROSS JOIN spfile_status s
  )
SELECT
  '- Current SGA total size (SGA_TARGET): ' ||
  TO_CHAR(
    ROUND(current_sga_target_bytes / 1048576, 1),
    'FM999,999,990.0'
  ) || ' MB' ||
  CHR(10) ||
  '  - Predefined SGA component sizes: ' ||
  TO_CHAR(
    ROUND(component_bytes / 1048576, 1),
    'FM999,999,990.0'
  ) || ' MB' ||
  CHR(10) ||
  '  - Component settings:' ||
  CHR(10) ||
  component_detail ||
  CHR(10) ||
  '- Current CPU_COUNT: ' ||
  TO_CHAR(cpu_count, 'FM999,999,990') ||
  CHR(10) ||
  '- Minimum SGA requirement for Oracle AI Database 26ai' ||
  CHR(10) ||
  '  RU 23.26.3 or newer: ' ||
  TO_CHAR(
    ROUND(minimum_sga_bytes / 1048576, 1),
    'FM999,999,990.0'
  ) || ' MB' ||
  CHR(10) ||
  CASE
    WHEN specified_count = 0 THEN
      'The SPFILE component values could not be read. Review' ||
      CHR(10) ||
      'component settings manually.'
    WHEN current_sga_target_bytes = 0 THEN
      'This calculation applies only when SGA_TARGET is greater' ||
      CHR(10) ||
      'than zero.'
    WHEN current_sga_target_bytes < minimum_sga_bytes THEN
      'You will need to increase SGA_TARGET by ' ||
      TO_CHAR(
        ROUND(
          (minimum_sga_bytes - current_sga_target_bytes) /
          1048576,
          1
        ),
        'FM999,999,990.0'
      ) || ' MB' ||
      CHR(10) ||
      'to a total of ' ||
      TO_CHAR(
        ROUND(minimum_sga_bytes / 1048576, 1),
        'FM999,999,990.0'
      ) || ' MB.' ||
      CHR(10) ||
      'Ensure SGA_MAX_SIZE can accommodate this value.'
    ELSE
      'Based on this estimate, you can upgrade or patch to' ||
      CHR(10) ||
      'Oracle AI Database 26ai RU 23.26.3 or newer without' ||
      CHR(10) ||
      'increasing SGA_TARGET.'
  END AS upgrade_check
FROM estimate;
