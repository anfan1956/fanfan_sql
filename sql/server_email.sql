USE MASTER
GO

SP_CONFIGURE 'show advanced options', 1
RECONFIGURE WITH OVERRIDE
GO

/* Enable Database Mail XPs Advanced Options in SQL Server */
SP_CONFIGURE 'Database Mail XPs', 1
RECONFIGURE WITH OVERRIDE
GO

SP_CONFIGURE 'show advanced options', 0
RECONFIGURE WITH OVERRIDE
GO


use fanfan
go

EXECUTE msdb.dbo.sysmail_help_profile_sp;  
declare @profile_name varchar(max)= 'fanfan_mail_admin'

EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = @profile_name,  
    @recipients = 'af.fanfan.2012@gmail.com',  
    @body = 'NEW SALE!!!',  
    @subject = 'Automated Success Message' ;  