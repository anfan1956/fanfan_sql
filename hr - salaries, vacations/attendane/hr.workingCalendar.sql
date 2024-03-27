--if OBJECT_ID ('hr.workingCalendar') is not null drop table hr.workingCalendar
go
--create table hr.workingCalendar
--(
--	attendanceid int not null identity primary key,
--	empid int not null foreign key references hr.employees (empid), 
--	divisionid int not null foreign key references org.divisions (divisionid),
--	attendanceDate date null, 
--	recorded datetime not null default current_timestamp, 
--	constraint uq_calendar unique (divisionid, attendanceDate)
--)


select * from hr.workingCalendar
