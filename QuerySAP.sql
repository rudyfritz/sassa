WITH BASIS_INFO AS /* Created for SAP HANA HotSpots (Note 2927209) Created by ZHONG, Mingqian (Tim) */ 
    (SELECT AREA,
         PORT
    FROM 
        (SELECT /* Modification section */ 'WORKLOAD' AREA, '30040' PORT
        FROM DUMMY )), PARA AS 
        (SELECT 'WORKLOAD' AREA, PORT, FILE_NAME, SECTION, KEY, VALUE, LAYER_NAME, MAP(LAYER_NAME,'DEFAULT',0,'SYSTEM',1,'TENANT',2,'DATABASE',2,'HOST',3) LAYER_ORDER, HOST
        FROM M_CONFIGURATION_PARAMETER_VALUES
        WHERE KEY IN ( 'bulk_load_threads', 'busy_executor_threshold', 'capture_thread_count', 'change_compression_threads', 'check_max_concurrency', 'check_max_concurrency_percent', 'default_statement_concurrency_limit', 'dynamic_parallel_insert_max_workers', 'enable_parallel_backup_encryption', 'estimate_compression_threads', 'get_candidates_threads', 'insert_max_threads', 'internal_check_max_concurrency', 'load_balancing_func', 'load_factor_job_wait_pct', 'load_factor_sys_wait_pct', 'loading_thread', 'max_concurrency', 'max_concurrency_dyn_min_pct', 'max_concurrency_hint', 'max_concurrency_hint_dyn_min_pct', 'max_concurrency_task_limit_factor', 'max_concurrent_connections', 'max_concurrent_queries', 'max_concurrency_rel', 'max_cpuload_for_parallel_merge', 'max_gc_parallelity', 'max_number_of_data_jobs', 'max_num_recompile_threads', 'max_sql_executors', 'num_cores', 'num_exec_threads', 'num_merge_threads', 'num_of_async_rep_queue', 'num_parallel_fox', 'other_threads_act_weight', 'other_worker_worker_weight_ratio', 'parallel_data_backup_backint_channels', 'parallel_merge_part_threads', 'parallel_merge_threads', 'prepare_threads', 'recovery_queue_count', 'row_order_optimizer_threads', 'split_history_parallel', 'split_threads', 'sql_executors', 'statement_memory_limit', 'statement_memory_limit_threshold', 'table_partition_size', 'tables_preloaded_in_parallel', 'threadpool', 'token_per_table', 'total_statement_memory_limit', 'total_statement_memory_limit_threshold', /* HANA Cloud */ 'default_statement_concurrency_limit_rel', 'default_statement_concurrency_max_limit', 'statement_memory_limit_rel', 'total_statement_memory_limit_rel' )
                AND FILE_NAME IN ( 'global.ini', 'indexserver.ini', 'nameserver.ini' )
                OR (FILE_NAME = 'daemon.ini'
                AND KEY = 'affinity')
        UNION ALL
        SELECT 'MERGE' AREA, PORT, FILE_NAME, SECTION, KEY, VALUE, LAYER_NAME, MAP(LAYER_NAME,'DEFAULT',0,'SYSTEM',1,'TENANT',2,'DATABASE',2,'HOST',3) LAYER_ORDER, HOST
        FROM M_CONFIGURATION_PARAMETER_VALUES
        WHERE KEY IN ( 'estimate_compression_threads', 'get_candidates_threads', 'load_balancing_func', 'parallel_merge_threads', 'prepare_threads', 'row_order_optimizer_threads', 'token_per_table' )
                AND FILE_NAME IN ('global.ini', 'indexserver.ini', 'nameserver.ini')
                OR SECTION IN ('mergedog', 'optimize_compression')
                AND FILE_NAME IN ('global.ini', 'indexserver.ini', 'nameserver.ini')
        UNION ALL
        SELECT 'GC' AREA, PORT, FILE_NAME, SECTION, KEY, VALUE, LAYER_NAME, MAP(LAYER_NAME,'DEFAULT',0,'SYSTEM',1,'TENANT',2,'DATABASE',2,'HOST',3) LAYER_ORDER, HOST
        FROM M_CONFIGURATION_PARAMETER_VALUES
        WHERE KEY IN ( 'gc_unused_memory_threshold_abs', 'gc_unused_memory_threshold_rel', 'async_free_target', 'async_free_threshold' )
                AND FILE_NAME IN ('global.ini', 'indexserver.ini', 'nameserver.ini') ), FILTER_PARA AS 
        (SELECT PARA.AREA AREA,
         FILE_NAME,
         SECTION,
         KEY,
         HOST,
         VALUE,
         LAYER_NAME,
         LAYER_ORDER
        FROM PARA, BASIS_INFO BI
        WHERE PARA.PORT LIKE BI.PORT
                AND (PARA.AREA LIKE BI.AREA
                OR INSTR(BI.AREA,
         PARA.AREA) != 0) ),
         SETPARA AS 
        (SELECT FILE_NAME,
        SECTION,
        KEY,
        HOST,
         MAX(LAYER_ORDER) LAYER_ORDER
        FROM FILTER_PARA
        GROUP BY  FILE_NAME,SECTION,KEY,HOST )
    SELECT P.AREA AREA,
         P.FILE_NAME FILE_NAME,
         P.SECTION SECTION,
         P.KEY KEY,
         MAP(PP.UNIT,
         NULL,
         P.VALUE,
         '',P.VALUE, P.VALUE||' ['||PP.UNIT||']') VALUE, P.LAYER_NAME LAYER_NAME, P.HOST HOST, PP.RESTART_REQUIRED RESTART_REQUIRED, PP.VALUE_RESTRICTIONS VALUE_RESTRICTIONS, PP.DESCRIPTION DESCRIPTION
FROM FILTER_PARA P
JOIN SETPARA S
    ON P.FILE_NAME = S.FILE_NAME
        AND P.SECTION = S.SECTION
        AND P.KEY = S.KEY
        AND P.LAYER_ORDER = S.LAYER_ORDER
        AND P.HOST = S.HOST LEFT OUTER
JOIN CONFIGURATION_PARAMETER_PROPERTIES PP
    ON PP.KEY = P.KEY
        AND PP.SECTION = P.SECTION
ORDER BY  AREA, FILE_NAME, SECTION, KEY, LAYER_NAME, HOST