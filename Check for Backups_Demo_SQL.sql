/*
Adapted from the open source sp_Blitz
No full backup in last 7 days
*/

SELECT  d.[name] AS DatabaseName ,
COALESCE(CAST(MAX(b.backup_finish_date) AS VARCHAR(25)),'No Backup Ever Made') AS LastFullBackup
FROM master.sys.databases AS D
LEFT OUTER JOIN msdb.dbo.backupset AS B ON D.name COLLATE SQL_Latin1_General_CP1_CI_AS = B.database_name 
COLLATE SQL_Latin1_General_CP1_CI_AS

AND B.type = 'D' /*Full backup*/
AND B.server_name = SERVERPROPERTY('ServerName') /*Backupset ran on server you're currently connected to. */

WHERE D.[name]<> 'tempdb'  /* Eliminate TempDB. No need to back that up */
AND D.state_desc NOT IN ('RESTORING', 'OFFLINE', 'OFFLINE_SECONDARY') /* Exclude databases that are offline or involved in log shipping, 
for example */
AND D.is_in_standby = 0 /* Exclude databases in stand-by state as part of log shipping*/
AND D.source_database_id IS NULL /* Excludes database snapshots */

GROUP BY d.name
HAVING MAX(B.backup_finish_date) <= GETDATE()-7 /*Full backup older than 7 days ago.*/
OR MAX(B.backup_finish_date) IS NULL

UNION ALL
/*
Show databases in Full recovery model
with no transaction log backup in the last 24 hours
*/

SELECT  d.[name] AS DatabaseName ,
COALESCE(CAST(MAX(b.backup_finish_date) AS VARCHAR(25)),'No Backup Ever Made') AS LastLogBackup
FROM master.sys.databases AS D
LEFT OUTER JOIN msdb.dbo.backupset AS B ON D.name COLLATE SQL_Latin1_General_CP1_CI_AS = B.database_name 
COLLATE SQL_Latin1_General_CP1_CI_AS

AND B.type = 'L' /*Log backup*/
AND B.server_name = SERVERPROPERTY('ServerName') /*Backupset ran on server you're currnetly connected to. */

WHERE D.[name]<> 'tempdb'  /* Eliminate TempDB. No need to back that up */
AND D.state_desc NOT IN ('RESTORING', 'OFFLINE', 'OFFLINE_SECONDARY') /* Exclude databases that are offline or involved in log shipping, 
for example */
AND D.is_in_standby = 0 /* Database is read-only to restore a log backup as in Log Shipping. */
AND D.source_database_id IS NULL /* Excludes database snapshots */
AND D.recovery_model_desc = 'Full'
GROUP BY d.name
HAVING MAX(B.backup_finish_date) <= GETDATE()-1 /*Log backup older than 1 day ago.*/
OR MAX(B.backup_finish_date) IS NULL; 

/*
Similar, and more results for other issues using sp_Blitz 
in the First Responder Kit
*/

exec DBAUtility.dbo.sp_Blitz 


/*
Provides issues that are priority 1, which will be 
backups and CHECKDB. This helps for the easily distracted!
*/
exec DBAUtility.dbo.sp_Blitz @IgnorePrioritiesAbove = 9