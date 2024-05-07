/*
'F:\sql backups\DailyBackup'
'fanfan'
'alexander.n.fedorov@gmail.com'
*/

USE msdb;
GO

-- Check if the job 'Database Backup Job' already exists
IF EXISTS (SELECT * FROM dbo.sysjobs WHERE name = 'Database Backup Job')
BEGIN
    -- Delete the job
    EXEC sp_delete_job @job_name = N'Database Backup Job';
END

-- Check if the schedule 'Daily Schedule' already exists
IF EXISTS (SELECT * FROM dbo.sysschedules WHERE name = 'Daily Schedule')
BEGIN
    -- Delete the schedule
    EXEC sp_delete_schedule @schedule_name = N'Daily Schedule';
END

-- Create a schedule to run every day at 3:20 AM
DECLARE @schedule_id INT;
EXEC sp_add_schedule
    @schedule_name = N'Daily Schedule',
    @freq_type = 4, -- Frequency type 4 means "Daily"
    @freq_interval = 1, -- Occurs every 1 day
    @active_start_time = 32000; -- Starts at 3:20 AM

-- Create the job
DECLARE @JobId binary(16);
EXEC sp_add_job
    @job_name = N'Database Backup Job',
    @enabled = 1,
    @notify_level_eventlog = 0,
    @notify_level_email = 0,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @delete_level = 0,
    @description = N'Job to backup the fanfan and CBRates databases every day at 3:20 AM.',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

-- Add a step to the job to backup fanfan database
EXEC sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Backup fanfan Database',
    @step_id = 1,
    @cmdexec_success_code = 0,
    @on_success_action = 3, -- Go to the next step
    @on_fail_action = 2, -- Quit the job reporting failure
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE fanfan TO DISK = N''D:\COMMON\SQLSERVER\DailyBackUp\fanfan.bak'' WITH NOFORMAT, INIT, NAME = N''fanfan-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, STATS = 10',
    @database_name = N'master',
    @flags = 0;

-- Add another step to the job to backup CBRates database
EXEC sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Backup CBRates Database',
    @step_id = 2,
    @cmdexec_success_code = 0,
    @on_success_action = 1, -- Quit the job reporting success
    @on_fail_action = 2, -- Quit the job reporting failure
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE CBRates TO DISK = N''D:\COMMON\SQLSERVER\DailyBackUp\CBRates.bak'' WITH NOFORMAT, INIT, NAME = N''CBRates-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, STATS = 10',
    @database_name = N'master',
    @flags = 0;

-- Attach the schedule to the job
EXEC sp_attach_schedule @job_id = @JobId, @schedule_name = N'Daily Schedule';

-- Add the job to the SQL Server Agent
EXEC sp_add_jobserver @job_id = @JobId, @server_name = N'(local)';
GO
