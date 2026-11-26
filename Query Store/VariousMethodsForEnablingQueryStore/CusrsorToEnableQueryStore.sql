
DECLARE @DBName  SYSNAME, @SQL NVARCHAR(MAX);

DECLARE db_cursor CURSOR FAST_FORWARD 

FOR 
SELECT [name]
from sys.databases 
WHERE is_query_store_on = 0
AND database_id > 4
AND [name] NOT LIKE 'SQLLab%';

OPEN db_cursor
FETCH NEXT FROM db_cursor
INTO @DBName

WHILE @@FETCH_STATUS = 0
	BEGIN
	
	SET @SQL = CONCAT('ALTER DATABASE  ', QUOTENAME(@DBName),  ' SET QUERY_STORE = ON (MAX_STORAGE_SIZE_MB = 4096);')
	PRINT @SQL
	exec sp_executesql @sql
	FETCH NEXT FROM db_cursor
	INTO @DBName
	END

CLOSE db_cursor
DEALLOCATE db_cursor

