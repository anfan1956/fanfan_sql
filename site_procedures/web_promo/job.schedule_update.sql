use fanfan
go
--select * from web.promo_log
--select * from inv.site_reservations s join inv.site_reserve_states r on r.reservation_stateid=s.reservation_stateid order by 1 desc;

--select * from inv.site_reservations r where r.reservation_stateid=inv.reservation_state_id('active')




if OBJECT_ID('job.schedule_update') is not null drop proc job.schedule_update
go
create proc job.schedule_update 
	@procName varchar(max), 
	@delay int, @note varchar(max) output 
as
set nocount on;

begin 
	declare @schedule_id varchar(max);

	if exists(select * from msdb.dbo.sysjobs where name = @procName)
		begin
			select @schedule_id = schedule_id from msdb.dbo.sysjobschedules s
				join msdb.dbo.sysjobs j on j.job_id=s.job_id
			where name=@procName;

			declare @time datetime = dateadd(MINUTE, @delay, getdate());
			declare @start_time int = (SELECT REPLACE(
						   CONVERT(VARCHAR(8), @time, 108),
						   ':', '') AS [StringVersion])

			EXEC msdb.dbo.sp_update_schedule  
				@schedule_id = @schedule_id,
				@active_start_time = @start_time,
				@enabled = 1
			
			update r set r.expiration=@time
			from inv.site_reservations r where r.reservationid=@procName;

			select @note = 
				--'время резервирования заказа № ' + @procName + ' - ' + 
			format(@time, 'dd.MM.yyyy года. время:  HH:mm' )
		end 

	else 
		select @note = 'the job ' +   @procName + ' does not exist'
end 
go

declare 
	@minutes int = 1,
	@procName varchar(max) = 77204, 
	@note varchar(max);
exec job.schedule_update @procname, @minutes, @note output;
select @note;

select 
	name, s.schedule_id,
	sj.next_scheduled_run_date, s.*
	,convert(char(8), next_run_time)
from msdb.dbo.sysjobs j 
		join msdb.dbo.sysjobschedules s on s.job_id=j.job_id
		join msdb.dbo.sysjobactivity AS sj on sj.job_id= j.job_id
where ISNUMERIC( name ) = 1

select * from inv.site_reservations order by 1 desc
