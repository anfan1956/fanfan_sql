
if OBJECT_ID('web.basketLogs') is not null drop table web.basketLogs
if OBJECT_ID('web.basket') is not null drop table web.basket
go

create table web.basket(
	logid int not null identity primary key, 
	uuid char(36)  null,
	custid int  null foreign key references cust.persons (personid), 
	logdate datetime not null default current_timestamp
)
create table web.basketLogs(
	logid int not null foreign key references web.basket (logid), 
	parent_styleid int not null, 
	color varchar(50) not null,
	size varchar(10) not null,
	qty int not null default (1),
	primary key (logid, parent_styleID, color, size)
)

select * from web.basket
select * from web.basketLogs
