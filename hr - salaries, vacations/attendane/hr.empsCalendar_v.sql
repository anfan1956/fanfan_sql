if OBJECT_ID ('hr.empsCalendar_v') is not null drop view hr.empsCalendar_v
go 
create view hr.empsCalendar_v as
select 
	p.lfmname сотрудник, d.divisionfullname магазин, 
		cast(attendanceDate as datetime) дата, 
		DATEPART(MM, attendanceDate) месяц, 
		DATEPART(yyyy, attendanceDate) год,
		DATEPART(iso_week, attendanceDate) - DATEPART(iso_week, DATEADD(DD, 1, eomonth(attendanceDate, -1))) + 1
		--DATEPART(iso_week, attendanceDate) 
		неделя, 
		FORMAT(attendanceDate, 'ddd', 'ru-ru') день, 
		1 кол
from hr.workingCalendar w
	join org.persons p on p.personID =w.empid
	join org.divisions d on d.divisionID=w.divisionid
where w.attendanceDate >= DATEADD(D, 1, EOMONTH(getdate(), -1))

go
select * from hr.empsCalendar_v
-- Set the first day of the week to Monday
SET DATEFIRST 1;

DECLARE @date DATE = '2024-03-10'; -- replace with your date

select DATEPART(iso_week, @date) - DATEPART(iso_week, DATEADD(DD, 1, eomonth(@date, -1))) + 1
select EOMONTH( @date, -1)