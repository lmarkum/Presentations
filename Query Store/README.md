# QueryStore

This repo holds queries and presentations on the topic of Query Store, as well as queries for various performance metric comparisons.


"QueryStoreBefore-AfterMetricComparison.sql"

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


