/*
*/
if OBJECT_ID ('fsc.attendance') is not null drop table fsc.attendance
if OBJECT_ID ('fsc.salesPersons') is not null drop table fsc.salesPersons
if OBJECT_ID ('fsc.divisions') is not null drop table fsc.divisions

create table fsc.salesPersons (
		personid int not null foreign key references org.users (userid), 
		dateStart date not null,
		dateFinish date null,
		primary key ( personid, datestart)
	)
create table fsc.divisions (
		divisionid int not null foreign key references org.divisions (divisionid), 
		dateStart date not null,
		dateFinish date null,
		primary key ( divisionid, datestart)
	)
go
Create table fsc.attendance (
	attendanceID int not null identity primary key,
	personid int not null, 
	att_date date not null,
	divisionID int not null foreign key references org.divisions (divisionid),
	unique (divisionid, att_date)	
)

declare @date date = '2025-01-01'

insert fsc.salesPersons (personid, dateStart)
values (5, @date), (7, @date), (10, @date)
;
insert fsc.divisions (divisionid, dateStart)
values (27, @date), (35, @date)

if OBJECT_ID('fsc.attendDivision_') is not null drop proc fsc.attendDivision_
go

create proc fsc.attendDivision_ @date datetime, @divisionid int as
set nocount on;
	begin 
		; with _count as (
			select 
				isnull(count(a.attendanceID), 0)
				pcount, 
				p.personid
			from fsc.salesPersons p
				left join fsc.attendance a on a.personid = p.personid 
					and a.att_date between DATEADD(DD, 1, EOMONTH(@date, -1)) and EOMONTH(a.att_date, 0)
			group by p.personid
		) 
		, _random as (
			select top 1 personid
			from _count c
				cross apply (
				select min(pcount) mcount
				from _count c
				) _min
			where c.pcount = _min.mcount
			order by NEWID()
		)
		, s as (
			select r.personid , @divisionid divisionid, @date att_date
			from _random r	
		)
		merge fsc.attendance as t using s on
			t.divisionid = s.divisionid and 
			t.att_date=s.att_date
		when not matched then 
		insert (personid, divisionID, att_date)
		values (personid, divisionID, att_date)
		;
		declare @r int
		select @@ROWCOUNT rowsCount;
		
	end 
go
