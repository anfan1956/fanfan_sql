/*
		-- do not uncomment, the tables are actually working
if OBJECT_ID('hr.periodCharges') is not null drop table hr.periodCharges
go 
if OBJECT_ID('hr.payrollItems') is not null drop table hr.payrollItems
go 

create table hr.payrollItems (
	itemid int not null identity primary key, 
	item varchar(50) not null unique
)

insert hr.payrollItems(item)
values ('cash'), ('bank'), ('PIT'), ('SocTax')

create table hr.periodCharges (
	personid int not null foreign key references org.persons (personid),
	itemid int not null foreign key references hr.payrollItems (itemid),
	amount money not null, 
	periodEndDate date not null, 
	primary key (personid, itemid, periodEndDate)
)
*/


if OBJECT_ID('hr.SBER_template_') is not null drop function hr.SBER_template_
go
create function hr.SBER_template_ (@date date) returns table  as return

select  u.phone Телефон, ps.lastname Фамилия, ps.firstname Имя, ps.middlename Очество, round(p.amount, 2) Сумма
from hr.periodCharges p
	join org.users u on u.userID=p.personid
	join org.persons ps on ps.personID=u.userID
where p.periodEndDate = @date and p.itemid =2

go

