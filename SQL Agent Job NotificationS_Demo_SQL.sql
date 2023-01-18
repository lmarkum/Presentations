
/*
Find failed SQL Agent jobs
*/
SELECT
J.Name AS JobName
, J.description AS JobDescription
, H.step_id
, H.step_name
, msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
, H.sql_severity
, H.message
FROM msdb.dbo.sysjobs AS J
INNER JOIN msdb.dbo.sysjobhistory AS H ON J.job_id = H.job_id
INNER JOIN msdb.dbo.sysjobsteps AS JS ON J.job_id = JS.job_id AND H.step_id = JS.step_id
WHERE H.run_status = 0 --Failed jobs

/*
How do you find SQL Agent jobs that have no email operators assigned?
*/

USE msdb;
GO

SELECT J.name,
 J.notify_level_email,--a zero means a value is not set.
 J.notify_email_operator_id --a zero means a value is not set.

FROM sysjobs AS J
 INNER JOIN sysjobschedules AS JS ON J.job_id = JS.job_id
 INNER JOIN sysschedules AS SS ON SS.schedule_id = JS.schedule_id
 
WHERE J.enabled = 1
 AND J.notify_level_email = 0 --never notify
 AND SS.enabled = 1; --it has a schedule that is enabled

 /*
 Fixing jobs with no email notification configured
 */

 /*
 Create an operator to use
 */
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'DBA Team', 
    @enabled=1, 
    @email_address=N'MyEmail@MyDomain.com'
GO
/*
Assign the operator to multiple jobs via T-SQL.
Keep in mind that in this example I am only updating jobs that 
don’t already have an operator assigned to them.  
This makes the WHERE clause very important.  
If you leave this off, copy and run the generated statements, 
then all jobs will be updated to whatever was specified in 
the variable. 

Notice that I am using sp_update_job not only to add the email operator, but 
also to set the job to log to the Windows event log in case of a failure.  
Why?  Well, what happens if database mail is not configured properly?
*/
use msdb
GO
DECLARE @operator varchar(50)
SET @operator = 'DBA Team' 

SELECT 'EXEC msdb.dbo.sp_update_job @job_name = ''' + 
j.[name] + ''' ,@notify_level_eventlog = 2, 
@notify_level_email = 2, @notify_email_operator_name = ''' + @operator + '''' 
FROM sysjobs As J
 INNER JOIN sysjobschedules AS JS ON J.job_id = JS.job_id
 INNER JOIN sysschedules AS SS ON SS.schedule_id = JS.schedule_id
 
WHERE J.enabled = 1 --Job is enabled
 AND J.notify_level_email = 0 -- the job is currently set to never notify
 AND SS.enabled = 1; --it has a schedule that is enabled


EXEC msdb.dbo.sp_update_job @job_name = 'syspolicy_purge_history' ,@notify_level_eventlog = 2,   @notify_level_email = 2, @notify_email_operator_name = 'DBA Team'
EXEC msdb.dbo.sp_update_job @job_name = 'syspolicy_purge_history' ,@notify_level_eventlog = 2,   @notify_level_email = 2, @notify_email_operator_name = 'DBA Team'
EXEC msdb.dbo.sp_update_job @job_name = 'syspolicy_purge_history' ,@notify_level_eventlog = 2,   @notify_level_email = 2, @notify_email_operator_name = 'DBA Team'
EXEC msdb.dbo.sp_update_job @job_name = 'Test Failed Jobs Detection' ,@notify_level_eventlog = 2,   @notify_level_email = 2, @notify_email_operator_name = 'DBA Team'



