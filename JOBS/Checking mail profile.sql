USE msdb;
GO



EXEC sysmail_help_profileaccount_sp
    @profile_name = 'fanfan_mail_admin'; -- Replace with your Database Mail profile name
go
DECLARE @dba_email NVARCHAR(255);

SELECT @dba_email = email_address 
FROM msdb.dbo.sysoperators 
WHERE name = 'DBA';

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'fanfan_mail_admin',
    @recipients = @dba_email,
    @subject = 'Test Email',
    @body = 'This is a test email.';
