Install-Module ImportExcel

Find-DbaInstance -ComputerName $env:COMPUTERNAME | SELECT * | Out-GridView

$File = 'C:\DBATools\Find-DbaInstanceOutput.xlsx' 
$TargetSqlInstance = 'skolarlee-pc\sql2019'
$TargetDatabaseName = 'DBAUtility'
$TargetSchema = 'dbo'
$TargetTable = 'SQLInstances'
Find-DbaInstance -ComputerName $env:COMPUTERNAME | SELECT * | Export-Excel $File -ClearSheet

(Import-Excel -Path $File) | Write-DbaDbTableData -SqlInstance $TargetSqlInstance -Database $TargetDatabaseName -Schema $TargetSchema -Table $TargetTable -AutoCreateTable
Read-SqlTableData -ServerInstance $TargetSqlInstance -Database $TargetDatabaseName -Schema $TargetSchema -Table $TargetTable


<# Code to run against Active Directory to make a SQL Server inventory. #>
$File = 'C:\DBATools\Find-DbaInstanceOutput.xlsx'
$TargetSqlInstance = 'skolarlee-pc\sql2019'
$TargetDatabaseName = 'DBAUtility'
$TargetSchema = 'dbo'
$TargetTable = 'SQLInstances'
#Install-Module ImportExcel #OR Import-Module to load it once it has been installed.

Get-ADComputer -Filter { name -like '*sql*' } | Find-DbaInstance | Select * | Export-Excel $File 
(Import-Excel -Path 'C:\DBATools\FindInstanceOutput.xlsx') | Write-DbaDbTableData -SqlInstance $TargetSqlInstance -Database $TargetDatabaseName `
-Schema $TargetSchema -Table $TargetTable -AutoCreateTable

Read-SqlTableData -ServerInstance $TargetSqlInstance -DatabaseName $TargetDatabaseName -SchemaName $TargetSchema -TableName $TargetTable