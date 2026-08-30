/*

Written by: Lee Markum

Date: September 2025

Purpose:
These queries retrieve Query Store query_id values, query_hash values, and
average performance metrics for queries executed during two different time
ranges. The results compare the average metric values from a baseline period
("before") with those from a comparison period ("after").

The goal is similar to the Query Store Tracked Queries report, but these
queries allow you to view the top N queries simultaneously and determine
whether each metric improved or regressed following a change.

The script selects the TOP (10) queries from the baseline period and compares
those same query_id values against the comparison period. This ensures that the
comparison is performed against the same set of queries rather than whatever
happened to be the top queries after the change. Some baseline query_id values
may not appear during the comparison period, which is why a LEFT JOIN is used.

This is particularly useful when establishing a performance baseline before a
SQL Server migration and comparing it with performance after the migration.
It can also be used to measure the impact of query tuning, index changes,
configuration changes, or other modifications.

The same approach can be applied to any performance metric stored in Query
Store, not just CPU usage.

Updated: August 3, 2026
- Added comparisons for additional Query Store performance metrics beyond CPU.
- Updated the comment block and removed the repeating variable DECLARE sections.

Updated: August 11, 2026
- Converted the separate CTEs for each metric into a single CTE for all metrics
- Added conversion of DATETIME parameters to UTC for proper comparison to Query Store tables 
- Starting to add logic for returning only the metric of interest, such as Avg CPU, Logical Reads, Logical Writes, Max Used Memory


Requirement: Query Store must have been enabled and in ReadWrite mode during the time periods under consideration.

*/

--Get into the database context of the Query Store that needs to be analyzed.
USE StackOverflow2013;
GO

DECLARE @DatabaseName SYSNAME; 
DECLARE @BeforeStart DATETIME; 
DECLARE @BeforeEnd DATETIME;
DECLARE @AfterStart DATETIME;
DECLARE @AfterEnd DATETIME;
DECLARE @TopCount INT;
DECLARE @Metric VARCHAR(30)

DECLARE @BeforeStartUTC datetimeoffset;
DECLARE @BeforeEndUTC   datetimeoffset;
DECLARE @AfterStartUTC  datetimeoffset;
DECLARE @AfterEndUTC    datetimeoffset;

SET @DatabaseName = 'StackOverFlow2013';
SET @BeforeStart = '2026-08-10 22:00';
SET @BeforeEnd = '2026-08-10 22:15';
SET @AfterStart = '2026-08-10 22:15';
SET @AfterEnd = '2026-08-10 22:30';
SET @TopCount = 10;
SET @Metric = 'AVG CPU';

SET @BeforeStartUTC = @BeforeStart AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'UTC';
SET @BeforeEndUTC   = @BeforeEnd   AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'UTC';
SET @AfterStartUTC  = @AfterStart  AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'UTC';
SET @AfterEndUTC    = @AfterEnd    AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'UTC';

WITH BaselineTopQueries
AS (
	SELECT TOP(@TopCount) qsq.query_hash
		,qsq.query_id
		,LEFT(qsqt.query_sql_text, 500) AS query_sql_text
		,SUM(qsrs.avg_cpu_time) AS avg_cpu_time_baseline
		,SUM(qsrs.avg_logical_io_reads) AS avg_logical_io_reads_baseline
		,SUM(qsrs.avg_logical_io_writes) AS avg_logical_io_writes_baseline
		,SUM(qsrs.avg_query_max_used_memory) AS avg_query_max_used_memory_baseline
		,SUM(qsrs.count_executions) AS ExecutionCount
	FROM sys.query_store_query qsq
	JOIN sys.query_store_plan qspt ON qsq.query_id = qspt.query_id
	JOIN sys.query_store_runtime_stats qsrs ON qspt.plan_id = qsrs.plan_id
	JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrs.runtime_stats_interval_id = qsrsi.runtime_stats_interval_id
	JOIN sys.query_store_query_text qsqt ON qsq.query_text_id = qsqt.query_text_id
	WHERE qsrsi.start_time >= @BeforeStartUTC
		AND qsrsi.end_time <= @BeforeEndUTC
	GROUP BY qsq.query_hash
		,qsq.query_id
		,qsqt.query_sql_text
	ORDER BY SUM(qsrs.avg_cpu_time) DESC
	)

,AfterStats
AS (
	SELECT qsq.query_hash
		,qsq.query_id
		,LEFT(qsqt.query_sql_text, 500) AS query_sql_text
		,SUM(qsrs.avg_cpu_time) AS avg_cpu_time_After
		,SUM(qsrs.avg_logical_io_reads) AS avg_logical_io_reads_After
		,SUM(qsrs.avg_logical_io_writes) AS avg_logical_io_writes_After
		,SUM(qsrs.avg_query_max_used_memory) AS avg_query_max_used_memory_After
		,SUM(qsrs.count_executions) AS ExecutionCount
	FROM sys.query_store_query qsq
	JOIN sys.query_store_plan qspt ON qsq.query_id = qspt.query_id
	JOIN sys.query_store_runtime_stats qsrs ON qspt.plan_id = qsrs.plan_id
	JOIN sys.query_store_runtime_stats_interval qsrsi ON qsrs.runtime_stats_interval_id = qsrsi.runtime_stats_interval_id
	JOIN sys.query_store_query_text qsqt ON qsq.query_text_id = qsqt.query_text_id
	WHERE qsrsi.start_time >= @AfterStartUTC
		AND qsrsi.end_time <= @AfterEndUTC
		AND qsq.query_id IN 
			(
			
			SELECT query_id
			FROM BaselineTopQueries
			
			)
			
	GROUP BY qsq.query_hash
		,qsq.query_id
		,qsqt.query_sql_text
	)


--Final output: Compare early vs. late metrics
SELECT BTQ.query_hash
	,BTQ.query_id
	,BTQ.query_sql_text
    ,BTQ.ExecutionCount AS BaselineExecutionCount
    ,A.Executioncount AS AfterExecutionCount
    ,CASE @Metric
        WHEN 'AVG CPU'
            THEN BTQ.avg_cpu_time_baseline
        WHEN 'Logical Reads'
            THEN BTQ.avg_logical_io_reads_baseline
		WHEN 'Logical Writes'
            THEN BTQ.avg_logical_io_writes_baseline
		WHEN 'Max Used Memory'
            THEN BTQ.avg_query_max_used_memory_baseline
    END AS BaselineMetric
	,CASE @Metric
        WHEN 'AVG CPU'
            THEN A.avg_cpu_time_After
        WHEN 'Logical Reads'
            THEN A.avg_logical_io_reads_After
		WHEN 'Logical Writes'
            THEN A.avg_logical_io_writes_After
		WHEN 'Max Used Memory'
            THEN A.avg_query_max_used_memory_After
    END AS AfterMetric
	,CASE @Metric
        WHEN 'AVG CPU'
            THEN ISNULL(A.avg_cpu_time_After, 0)
                 - BTQ.avg_cpu_time_baseline

        WHEN 'Logical Reads'
            THEN ISNULL(A.avg_logical_io_reads_After, 0)
                 - BTQ.avg_logical_io_reads_baseline
		WHEN 'Logical Writes'
            THEN ISNULL(A.avg_logical_io_writes_After, 0)
                 - BTQ.avg_logical_io_writes_baseline
		WHEN 'Max Used Memory'
            THEN ISNULL(A.avg_query_max_used_memory_After, 0)
                 - BTQ.avg_query_max_used_memory_baseline
    END AS MetricChange
	,BTQ.avg_cpu_time_baseline
	,A.avg_cpu_time_After
	,(ISNULL(A.avg_cpu_time_After, 0) - BTQ.avg_cpu_time_baseline) AS cpu_change
	,BTQ.avg_logical_io_reads_baseline
	,A.avg_logical_io_reads_After
	,(ISNULL(A.avg_logical_io_reads_After, 0) - BTQ.avg_logical_io_reads_baseline) AS logical_io_reads_change
	,BTQ.avg_logical_io_writes_baseline
	,A.avg_logical_io_writes_After
	,(ISNULL(A.avg_logical_io_writes_After, 0) - BTQ.avg_logical_io_writes_baseline) AS logical_io_writes_change
	,BTQ.avg_query_max_used_memory_baseline
	,A.avg_query_max_used_memory_After
	,(ISNULL(A.avg_query_max_used_memory_After, 0) - BTQ.avg_query_max_used_memory_baseline) AS avg_query_max_used_memory_change
FROM BaselineTopQueries AS BTQ
LEFT JOIN AfterStats A ON BTQ.query_id = A.query_id
ORDER BY
    CASE @Metric
        WHEN 'AVG CPU'       THEN BTQ.avg_cpu_time_baseline
        WHEN 'Logical Reads' THEN BTQ.avg_logical_io_reads_baseline
		WHEN 'Logical Writes' THEN BTQ.avg_logical_io_writes_baseline
		WHEN 'Max Used Memory' THEN BTQ.avg_query_max_used_memory_baseline
    END DESC;