USE msdb
go
if OBJECT_ID('dbo.sp_add_job_quick') is not null drop proc dbo.sp_add_job_quick
go
CREATE procedure dbo.sp_add_job_quick 
@job nvarchar(128),
@mycommand nvarchar(max), 
@servername nvarchar(28),
@startdate nvarchar(8),
@starttime nvarchar(8)
as
--Add a job
EXEC dbo.sp_add_job
    @job_name = @job, @delete_level = 1 ;
--Add a job step named process step. This step runs the stored procedure
EXEC sp_add_jobstep
    @job_name = @job,
    @step_name = N'process step',
    @subsystem = N'TSQL',
    @command = @mycommand
--Schedule the job at a specified date and time
exec sp_add_jobschedule @job_name = @job,
@name = 'MySchedule',
@freq_type=1,
@active_start_date = @startdate,
@active_start_time = @starttime
-- Add the job to the SQL Server 
EXEC dbo.sp_add_jobserver
    @job_name =  @job,
    @server_name = @@SERVERNAME