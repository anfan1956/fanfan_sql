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


if OBJECT_ID ('hr.periodCharges_update_') is not null drop proc hr.periodCharges_update_
if type_ID ('hr.chargeType') is not null drop type hr.chargeType
create type hr.chargeType as table (
	personid int, 
	amount money, 
	item varchar(50)
)
go

create proc hr.periodCharges_update_ @charge hr.chargeType readonly, @chargeDate date as
begin
	with s (personid, amount, itemid, periodEndDate ) as (
		select c.personid, amount, itemid, @chargeDate  
		from @charge c
			join hr.payrollItems i on i.item =c.item
		)
		merge hr.periodCharges as t using s
		on	
			t.personid = s.personid and
			t.itemid =s.itemid and
			t.periodEndDate=s.periodEndDate
		when matched then update  set
				t.amount= s.amount
		when not matched then 
			insert (personid, amount, itemid, periodEndDate )
			values (personid, amount, itemid, periodEndDate );
		
end 
go
declare @periodEndDate date = '20240215';
select * from hr.SBER_template_(@periodEndDate, 'cash')
select * from hr.periodCharges order by 4 desc;