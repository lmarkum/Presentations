/*
Written by: Lee Markum
Date: September 2025
Purpose:This query retrieves the queryIDs, query hash and average CPU for those queries in a given time range and compares 
the AVG CPU metric from before and after.

This is useful for captureing performance prior to a SQL Server migration and then after for the same set of queries.
This could also be useful for a before/after comparison after any change to a query.

This sort of query cuold be done with other query perofrmance metrics stored in Query Store.

*/

--First CTE: Get top 10 CPU-intensive queries from before the migration

USE StackOverflow2013;
GO

WITH FilteredTop10
AS (
	SELECT TOP 10 qsq.query_hash,qsq.query_id, qsqt.query_sql_text
		,AVG(qsrs.avg_cpu_time) AS avg_cpu_time_early
	FROM sys.query_store_query qsq
	JOIN sys.query_store_plan qspt ON qsq.query_id = qspt.query_id
	JOIN sys.query_store_runtime_stats qsrs ON qspt.plan_id = qsrs.plan_id
	JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrs.runtime_stats_interval_id = 
	qsrsi.runtime_stats_interval_id
JOIN sys.query_store_query_text qsqt
    ON qsq.query_text_id = qsqt.query_text_id
	WHERE qsrsi.start_time >= '2025-09-27 15:00:00'
		AND qsrsi.end_time < '2025-09-27 16:00:00'
	GROUP BY qsq.query_hash
		,qsq.query_id
		,qsqt.query_sql_text
	ORDER BY AVG(qsrs.avg_cpu_time) DESC
	)

--Pass into the below the queryIDs from before the migration to retreive the metrics for those queries for after the migration.
,LaterCpuStats
AS (
	SELECT qsq.query_id,qsqt.query_sql_text,AVG(qsrs.avg_cpu_time) AS avg_cpu_time_late
	FROM sys.query_store_query qsq
	JOIN sys.query_store_plan qspt ON qsq.query_id = qspt.query_id
	JOIN sys.query_store_runtime_stats qsrs ON qspt.plan_id = qsrs.plan_id
	JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrs.runtime_stats_interval_id = 
	qsrsi.runtime_stats_interval_id
JOIN sys.query_store_query_text qsqt
    ON qsq.query_text_id = qsqt.query_text_id 
	WHERE qsrsi.start_time >= '2025-09-27 16:00:00'
		AND qsrsi.end_time < '2025-10-01 00:00:00'
		AND qsq.query_id IN (
			
SELECT query_id
			FROM FilteredTop10

			)
	GROUP BY qsq.query_hash
		,qsq.query_id
		,qsqt.query_sql_text
	)


	--Final output: Compare early vs. late CPU averae usage
SELECT f.query_hash
	,f.query_id
, f.query_sql_text
	,f.avg_cpu_time_early
	,l.avg_cpu_time_late
	,(ISNULL(l.avg_cpu_time_late, 0) - f.avg_cpu_time_early) AS cpu_change
FROM FilteredTop10 f
LEFT JOIN LaterCpuStats l ON f.query_id = l.query_id
ORDER BY f.avg_cpu_time_early DESC;
