use fanfan
go

if OBJECT_ID('hr.active_emps_on_date') is not null drop function hr.active_emps_on_date
go
create function hr.active_emps_on_date(@date date ) returns table as return

with _comp_all as (
	select cs.*, p.commission, ROW_NUMBER () over (partition by cs.positionid order by date_start desc)  num
	from hr.compensation_schedule_21 cs
		join hr.positions_21 p on p.positionid= cs.positionid
	where isnull(date_finish, @date)>=@date
)
, _comp_s (positionid, hour_wage, fixed_wage, date_start, commission) as (
	select positionid, hour_wage, fixed_wage, date_start, commission 
	from _comp_all 
	where num =1
)
, _emps_all (personid, positionid, num) as (
	select distinct personid,
	positionid, 
	ROW_NUMBER () over (partition by positionid, personid order by date_start desc)  num
	from hr.schedule_21 s		
	where isnull(date_finish, @date)>=@date
)
, _emps (personid, person) as ( 
select distinct e.personid, p.lfmname
from _emps_all e
	join org.persons p on p.personID = e.personid
	join _comp_s c on c.positionid= e.positionid
where e.num=1 and c.commission = 'True'
)
select * from 
	_emps
go

declare @date date ='20220903';
select * from hr.active_emps_on_date(@date)