if OBJECT_ID('web.deliveriesSMS_log') is not null drop table web.deliveriesSMS_log
if OBJECT_ID('web.deliveries') is not null drop table web.deliveries
if OBJECT_ID('web.deliveryTypes') is not null drop table web.deliveryTypes
create table web.deliveryTypes(
deliveryTypeid int not null identity primary key,
deliveryType varchar(max) not null
)
go
insert web.deliveryTypes values ('самовывоз'), ('доставка')
create table web.deliveries(
	deliveryid int not null identity primary key,
	deliverytypeid int not null foreign key references web.deliveryTypes (deliveryTypeid),
	orderid int not null references inv.site_reservations (reservationid),
	divisionid int not null references org.divisions(divisionid),
	time_created datetime not null default current_timestamp,
	userid int not null foreign key references org.users,
	contractorid int  foreign key references org.contractors,
	contractorPhone char(10), -- check (deliverytypeid = 1 or contractorPhone is not null),
	courierPhone char(10) null,
	deliveryState varchar(25) default 'active' check(deliveryState in ('active', 'cancelled', 'executed')),
	deliveryDate datetime null,
	constraint ck_contractorid check ( deliverytypeid = 1 or contractorid is not null),
	constraint ck_contractorPhone check ( deliverytypeid = 1 or contractorPhone is not null)
)
create table web.deliveriesSMS_log(
	logid int not null identity primary key,
	logtime datetime default current_timestamp,
	deliveryid int foreign key references web.deliveries(deliveryid),
	smsCode char (5) not null,
	success bit default 'False'
)

select * from web.deliveryTypes


