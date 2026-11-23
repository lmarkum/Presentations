
<#

Enable Query Store for a single database.

#>

Set-DbatoolsInsecureConnection -SessionOnly
Set-DbaDbQueryStoreOption -SqlInstance SQL01 -State ReadWrite `
-FlushInterval 900 -CollectionInterval 60 -MaxSize 4096 `
-CaptureMode Auto -CleanupMode Auto -StaleQueryThreshold 30 `
-database "mytestdb"

<#

Enable Query Store for all user databases.
Be wary of doing this on a contained AG, because this will run on and 
fail against the contained system databases.

#>

Set-DbaToolsInsecureConnection –SessionOnly
Set-DbaDbQueryStoreOption -SqlInstance SQL01 -State ReadWrite `
-FlushInterval 900 -CollectionInterval 60 -MaxSize 4096 `
-CaptureMode Auto -CleanupMode Auto -StaleQueryThreshold 30 `
-AllDatabases #(or use –database and provide a list of DB names)


<#

Use a Central Management Server

#>
$SQLInstances = Get-DbaRegServer -Group 'prod'

Set-DbaToolsInsecureConnection –SessionOnly
Set-DbaDbQueryStoreOption -SqlInstance $SQLInstances -State ReadWrite `
-FlushInterval 900 -CollectionInterval 60 -MaxSize 4096 `
-CaptureMode Auto -CleanupMode Auto -StaleQueryThreshold 30 `
-AllDatabases -WhatIf #(or use –database and provide a list of DB names)

<#
Use a text file that has a list of servers
#>


Set-DbaToolsInsecureConnection –SessionOnly
$SQLInstances = Get-Content -Path "C:\Users\Public\Documents\ServerList.txt"



Set-DbaDbQueryStoreOption -SqlInstance $SQLInstances -State ReadWrite `
-FlushInterval 900 -CollectionInterval 60 -MaxSize 4096 `
-CaptureMode Auto -CleanupMode Auto -StaleQueryThreshold 30 `
-AllDatabases  #(or use –database and provide a list of DB names)


<#
Call an existing T-SQL Script
#>

Set-DbaToolsInsecureConnection –SessionOnly

$SqlInstance ='SQL01'

Invoke-DbaQuery -SqlInstance $SQLInstance -File 'C:\Users\lmarkum\Documents\codebank\CursorToEnableQueryStore_AllDatabases.sql'

