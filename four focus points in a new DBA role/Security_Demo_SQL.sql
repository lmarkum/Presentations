/*
Server principals and their role.
*/
Use master;
GO
SELECT  roles.principal_id AS RolePrincipalID,  
roles.name AS RolePrincipalName,  server_role_members.member_principal_id  AS MemberPrincipalID,  
members.name AS MemberPrincipalName

FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS members 
    ON server_role_members.member_principal_id = members.principal_id
WHERE members.name NOT LIKE 'NT SERVICE%';

/*  
Server permissions by role you're interested in.
*/
exec DBAUtility.dbo.sp_SrvPermissions @Role = 'sysadmin';

/*  
Server permissions by server principal you're interested in.
*/
exec DBAUtility.dbo.sp_SrvPermissions @Principal = 'MAPToolkit';

/*
Server permissions by database you're interested in.
*/

exec DBAUtility.dbo.sp_dbPermissions @DbName = 'CollegeFootball';

/*This option users a cursor to loop through all the databases on the instance*/
exec DBAUtility.dbo.sp_dbPermissions @DbName = 'ALL';

/*
Again can run the entire output from sp_Blitz
*/
exec DBAUtility.dbo.sp_Blitz;

/*
If you want to stay focused on just the security findings so
you're not distracted by other findings, then you can do that!
*/
exec DBAUtility.dbo.sp_Blitz @IgnorePrioritiesBelow = 229; 
