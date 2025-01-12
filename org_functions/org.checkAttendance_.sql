
if OBJECT_ID('org.checkAttendance_') is not null drop function org.checkAttendance_
go 
create function org.checkAttendance_ (@periodEnd date) returns varchar(max) as
Begin
	declare @note varchar(max);
	with s as (
	select
		cast (a.checktime as date) errorDate
	from org.attendance a
		cross apply (select periodStart =case datepart(dd, @periodEnd) 
			when 15 then dateadd (dd, 1, eomonth(@periodEnd, -1))
			else dateadd (dd, 16, eomonth(@periodEnd, -1))
			end 
			) as ps(periodStart)

	where 1=1
		and cast(checktime as date) between ps.periodStart and @periodEnd
--		and workstationID =23
	group by cast (a.checktime as date)
	having count(1) % 2 = 1) 
	select @note = STRING_AGG( errorDate, ', ') from S

	select @note = isnull('error dates:' + @note + ' ', 'OK')

	return @note
end
go
declare @periodEnd date= '20241231'
select org.checkAttendance_(@periodEnd)
if org.checkAttendance_(@periodEnd) = 'OK'select 'Wow!'