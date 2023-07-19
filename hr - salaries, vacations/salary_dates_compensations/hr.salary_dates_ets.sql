if OBJECT_ID('hr.salary_next_date_f') is not null drop function hr.salary_next_date_f
go
create function hr.salary_next_date_f() returns date as 
begin

	declare @salary_next date;
	select @salary_next = DATEADD(DD, 10, salary_date)  from hr.salary_dates
	where success is null 
	order by salary_date
	offset 0 rows
	fetch next 1 rows only;
	return @salary_next;
end 
go

--select hr.next_salary_date_f()
--select * from hr.salary_dates s where s.success is null

if OBJECT_ID('hr.salary_first_last_dates_f') is not null drop function hr.salary_first_last_dates_f
go
create function hr.salary_first_last_dates_f() returns table as return
	with _date as (
	select salary_date from hr.salary_dates
		where success is not null 
		order by salary_date desc
		offset 0 rows
		fetch next 1 rows only) 
	, _dates as (
	select salary_date, ROW_NUMBER() over  (order by salary_date) num
	from hr.salary_dates s
	where s.salary_date >= 
	(select salary_date from _date)
	order by salary_date
	offset 0 rows
	fetch next 2 rows only
	)
	select d.salary_date date_first, d2.salary_date date_last
	from _dates d
		join _dates d2 on d2.num<>d.num
	where d.num =1
go

if OBJECT_ID('hr.salary_first_date') is not null drop function hr.salary_first_date
go
create function hr.salary_first_date() returns date as 
	begin 
		declare @firstDate date;
	
		select @firstDate = DATEADD(DD, 1, salary_date)
			from hr.salary_dates s
			where s.success is not null
			order by salary_date desc
		offset 0 rows
			fetch next 1 rows only
			return @firstdate;
	end
go

if OBJECT_ID('hr.salary_last_date') is not null drop function hr.salary_last_date
go
create function hr.salary_last_date() returns date as 
	begin 
		declare @lastDate date;
	
		select top 1 @lastDate
			= salary_date 
		from hr.salary_dates s
		where s.success is null
		order by salary_date 	

		return @lastDate;
	end
go

--select hr.salary_first_date(); select hr.salary_last_date();select * from hr.salary_first_last_dates_f()	;


if object_id ('hr.compensation_latest_f') is not null drop function  hr.compensation_latest_f
go
create function hr.compensation_latest_f () returns table as return
with s as (
select distinct s.personid, p.positionnameid, s.date_start, s.has_MW, 
	ROW_NUMBER () over (partition by s.personid order by c.date_start desc, s.date_start desc ) num,
	isnull(c.fixed_wage, 0) fixed_wage, 
	pn.positionname, c.hour_wage hour_wage
from hr.schedule_21 s
	join hr.positions_21 p on p.positionid=s.positionid
	join hr.compensation_schedule_21 c on c.positionid=s.positionid
	join hr.position_names pn on pn.positionnameid= p.positionnameid
where s.date_finish is null
)
select 
	s.personid, 
	s.has_MW, 
	s.fixed_wage, 
	s.hour_wage, 
	s.positionname, 
	s.has_MW * hr.parameter_value_f('минималка/мес', null)* (1-isnull(sign(s.hour_wage), 0)) MW,
	s.has_MW * hr.parameter_value_f('минималка/час', null) * isnull(sign(s.hour_wage), 0) MW_hour,
	p.lfmname 
from s 
	join org.persons p on p.personID =s.personid
where num =1
go

select * from hr.compensation_latest_f()

