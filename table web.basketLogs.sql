
if OBJECT_ID('web.basketLogs') is not null drop table web.basketLogs
if OBJECT_ID('web.basket') is not null drop table web.basket
go

create table web.basket(
	logid int not null identity primary key, 
	uuid char(36) not null,
	custid int not null foreign key references cust.persons (personid), 
	logdate datetime not null default current_timestamp
)
create table web.basketLogs(
	logid int not null foreign key references web.basket (logid), 
	sortCodeId int not null, 
	price money null, 
	discount dec(3, 2) null default (0), 
	promoDiscount dec (3,2) null default (0), 
	customerDiscount dec (3,2) null default (0),
	qty int not null default (1),
	primary key (logid, sortCodeId)
)

select * from web.basket
select * from web.basketLogs
