use fanfan
go
if OBJECT_ID ('org.attendance_check_v') is not null drop view org.attendance_check_v
go
create view org.attendance_check_v as

	with t as (
		select a.*, count (attendanceID) over (partition by cast(checktime as date)) num
		from org.attendance a
		where 
			--a.personID = 67		and 
			year(checktime) = 2023 and 
			cast(checktime  as date)<cast(getdate() as date) and 
			a.personID >1
	)
	select 
		--* 
		distinct cast(t.checktime as date) irreg_date, 
		t.personID, p.lfmname person, t.num registrations
	from t
		join org.persons p on p.personID =t.personID
	where t.num % 2 <>0
go

select * from org.attendance_check_v



select * 
from hr.salary_jobs_log l
--where logid = 29
order by 2 desc

select  DATEADD(dd, -10,  hr.salary_next_date_f())
select hr.salary_date_f()
