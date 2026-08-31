/*
Demo lightweight Query Profiling

1. Enable the feature with TF 7412 on 2016/2017.
2. Run the SO query in one session.
3. Get the session ID from #2 and plug it into the Bobsql query and run
*/

USE StackOverflow2013;
GO


SELECT P.*, C.*
FROM dbo.Posts AS P
LEFT JOIN dbo.Comments AS C ON p.Id = C.PostId
ORDER BY P.LastEditDate


/*
https://github.com/microsoft/bobsql/blob/master/sql2019book/ch2_intelligent_performance/lwp/show_active_queries.sql
*/
SELECT session_id, physical_operator_name, node_id, thread_id, row_count, estimate_row_count
FROM sys.dm_exec_query_profiles
WHERE session_id <> @@SPID
ORDER BY session_id, node_id DESC
GO


/*
https://dba.stackexchange.com/questions/139191/sql-server-how-to-track-progress-of-create-index-command
*/
DECLARE @SPID INT = 56; -- << set your session_id (SPID)

/* Request-level info from dm_exec_requests */
;WITH req AS (
SELECT 
    r.session_id,
    r.request_id,
    r.command,
    r.status,
    r.start_time,                               -- UTC
    r.percent_complete,                         -- 0..100 when  available
    DATEDIFF(SECOND, r.start_time, SYSUTCDATETIME()) AS elapsed_sec_utc
FROM sys.dm_exec_requests AS r
WHERE r.session_id = @SPID
),
/* Operator-level progress (approximation) from dm_exec_query_profiles */
prof AS (
SELECT 
    qp.session_id,
    /* Aggregate rows processed and estimated rows for selected operators */
    SUM(qp.row_count) AS rows_processed,
    SUM(qp.estimate_row_count) AS total_rows,
    /* Current operator name for context */
    MAX(
        CASE 
            WHEN qp.close_time = 0 AND qp.first_row_time > 0 THEN qp.physical_operator_name
            ELSE N'<Transition>'
        END
    ) AS current_step
FROM sys.dm_exec_query_profiles AS qp
WHERE qp.session_id = @SPID
  AND qp.physical_operator_name IN (N'Table Scan', N'Clustered Index Scan', N'Index Scan', N'Sort')
GROUP BY qp.session_id
)
SELECT
c.session_id,
c.command,
c.status,
c.start_time                          AS start_time_utc,
c.elapsed_sec_utc                     AS elapsed_seconds_utc,
CONVERT(varchar(12), DATEADD(SECOND, c.elapsed_sec_utc, '19000101'), 108) AS elapsed_hhmmss,
CASE 
    WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 
        THEN c.percent_complete
    WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL
        THEN CONVERT(decimal(6,2), (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0))
    ELSE NULL
END AS percent_complete,
/* ETA components based on the unified percent */
CASE 
    WHEN (CASE 
            WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
            WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
            ELSE NULL
          END) > 0
        THEN CAST(c.elapsed_sec_utc / ((CASE 
                                         WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
                                         WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
                                         ELSE NULL
                                       END) / 100.0) AS INT)
    ELSE NULL
END AS estimated_total_seconds,
CASE 
    WHEN (CASE 
            WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
            WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
            ELSE NULL
          END) > 0
        THEN CAST((c.elapsed_sec_utc / ((CASE 
                                         WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
                                         WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
                                         ELSE NULL
                                       END) / 100.0)) - c.elapsed_sec_utc AS INT)
    ELSE NULL
END AS remaining_seconds,
CASE 
    WHEN (CASE 
            WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
            WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
            ELSE NULL
          END) > 0
        THEN CONVERT(varchar(12), DATEADD(SECOND, 
             CAST((c.elapsed_sec_utc / ((CASE 
                                         WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
                                         WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
                                         ELSE NULL
                                       END) / 100.0)) - c.elapsed_sec_utc AS INT), '19000101'), 108)
    ELSE NULL
END AS remaining_hhmmss,
/* UTC ETA */
CASE 
    WHEN (CASE 
            WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
            WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
            ELSE NULL
          END) > 0
        THEN DATEADD(SECOND, 
             CAST((c.elapsed_sec_utc / ((CASE 
                                         WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
                                         WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
                                         ELSE NULL
                                       END) / 100.0)) - c.elapsed_sec_utc AS INT), SYSUTCDATETIME())
    ELSE NULL
END AS estimated_completion_time_utc,
/* Local-time ETA (IST on your server if local time is IST) */
CASE 
    WHEN (CASE 
            WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
            WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
            ELSE NULL
          END) > 0
        THEN DATEADD(SECOND, 
             CAST((c.elapsed_sec_utc / ((CASE 
                                         WHEN c.percent_complete IS NOT NULL AND c.percent_complete > 0 THEN c.percent_complete
                                         WHEN p.total_rows IS NOT NULL AND p.total_rows > 0 AND p.rows_processed IS NOT NULL THEN (p.rows_processed * 100.0) / NULLIF(p.total_rows, 0)
                                         ELSE NULL
                                       END) / 100.0)) - c.elapsed_sec_utc AS INT), SYSDATETIME())
    ELSE NULL
END AS estimated_completion_time_local
FROM req AS c
LEFT JOIN prof AS p
ON p.session_id = c.session_id;



