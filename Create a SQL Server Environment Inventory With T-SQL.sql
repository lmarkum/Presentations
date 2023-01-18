/*
1. Open a SQL Server Management server 
2. Connect to all instances.

Make the DBAUtility database if it doesn't exist.
This simple syntax will put the database in the default data and 
log directories for the SQL instance.
*/
USE master;
GO
IF NOT EXISTS(SELECT * 
			 FROM sys.databases 
			 WHERE [name] = 'DBAUtility'
			 )
	BEGIN
	CREATE DATABASE DBAUtility
	END

USE DBAUtility;
GO

/*The CREATE OR ALTER syntax will only work on SQL Server 2016 and above
This could be converted to the older style "IF EXISTS...DROP" process

IF EXISTS(SELECT *
			FROM Information_Schema.Views
			WHERE Table_Name = 'GetSQLServerProperties'
			AND Table_Schema = 'dbo'
			)
DROP VIEW dbo.GetSQLServerProperties
*/
CREATE OR ALTER VIEW GetSQLServerProperties
AS
SELECT 
	GETDATE() AS DateRan,
	SERVERPROPERTY('MachineName') AS [ServerName],
	  CASE WHEN SERVERPROPERTY('InstanceName') IS NULL THEN 'MSSQLSERVER'
	  ELSE SERVERPROPERTY('InstanceName')
	  END AS [SQLServerInstanceName], 
	  CASE 
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '8%' THEN 'SQL2000'
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '9%' THEN 'SQL2005'
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.0%' THEN 'SQL2008'
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.5%' THEN 'SQL2008 R2'
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '11%' THEN 'SQL2012'
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '12%' THEN 'SQL2014'
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '13%' THEN 'SQL2016'     
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '14%' THEN 'SQL2017' 
		 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '15%' THEN 'SQL2019' 
		 ELSE 'unknown'
	  END AS ProductVersion,
	SERVERPROPERTY('ProductUpdateLevel') AS CULevel,
	SERVERPROPERTY('Edition') AS [Edition],
	SERVERPROPERTY('ProductVersion') AS [ProductVersionNumber];

GO

/*This DROP TABLE IF EXISTS syntax will only work on SQL Server 2016 and above.
This could be converted to the older style "IF EXISTS DROP TABLE" syntax.

IF EXISTS(SELECT *
			FROM Information_Schema.Views
			WHERE Table_Name = 'SQLServerProperties'
			AND Table_Schema = 'dbo'
			)
DROP TABLE dbo.SQLServerProperties
*/
DROP TABLE IF EXISTS dbo.SQLServerProperties
CREATE TABLE dbo. SQLServerProperties
(
Id INT IDENTITY (1,1) NOT NULL,
DateRan DateTime2(7) NOT NULL,
ServerName VARCHAR(20) NOT NULL,
SQLServerInstanceName VARCHAR(50) NOT NULL,
ProductVersion CHAR(7) NOT NULL,
CULevel VARCHAR(4) NULL,
Edition VARCHAR(40) NOT NULL,
ProductVersionNumber VARCHAR(15) NOT NULL,
CONSTRAINT PK_SQLServerProperties PRIMARY KEY CLUSTERED (Id),
/*Unique index below prevents the same server name and instance 
name from being entered into the database twice.

Uses inline index creation syntax, which only works on modern versions
of SQL Server.
*/
INDEX IX_ServerName_InstanceName UNIQUE NONCLUSTERED (ServerName, SQLServerInstanceName)

);

GO

/*This will only work on SQL Server 2016 and above
This could be converted to the older style 
"Check for existence and DROP if it exists" process

IF EXISTS(SELECT *
			FROM sys.procedures
			WHERE Name = 'SQLServerPropertiesInsert'
			)
DROP PROCEDURE dbo.SQLServerPropertiesInsert
*/
CREATE OR ALTER PROCEDURE dbo.SQLServerPropertiesInsert
AS
INSERT INTO SQLServerProperties

SELECT 
 GETDATE() AS DateRan,
 CONVERT(VARCHAR(20),[ServerName]), 
 CONVERT(VARCHAR(50),[SQLServerInstanceName]), 
 CONVERT(CHAR(7),[ProductVersion]), 
 CONVERT(VARCHAR(4),[CULevel]), 
 CONVERT(VARCHAR(40),[Edition]), 
 CONVERT(VARCHAR(15),[ProductVersionNumber])
 FROM dbo.GetSQLServerProperties;
 
 /*
 Example call to retrieve the data from the view
SELECT *
FROM dbo.GetSQLServerProperties;
 
Example call to insert the data to the table
exec dbo.SQLServerPropertiesInsert

--TRUNCATE TABLE dbo.SQLServerProperties 

SELECT *
FROM dbo.SQLServerProperties
 */

