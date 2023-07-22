
if OBJECT_ID('web.delivery_parcels') is not null drop table web.delivery_parcels
if OBJECT_ID ('web.deliveryLogs') is not null drop table web.deliveryLogs
if OBJECT_ID ('web.deliveryAddresses') is not null drop table web.deliveryAddresses

go
create table web.deliveryAddresses (
	addressid int not null identity primary key,
	address_string varchar (max) not null
)

create table web.deliveryLogs (
logid int not null identity primary key,
logtime datetime not null default current_timestamp,
empid int not null foreign key references org.users (userid),
divisionid int not null foreign key references org.divisions (divisionid),
addressid int null foreign key references web.deliveryAddresses (addressid),
custid int not null foreign key references cust.persons (personid),
recipient varchar(100) null, 
recipient_phone char(10) null,
orderid int null foreign key references inv.site_reservations (reservationid),
delivered bit 
)

create table web.delivery_parcels(
logid int not null foreign key references web.deliveryLogs (logid),
barcodeid int not null foreign key references inv.barcodes, 
primary key (logid,  barcodeid)
)

select * from web.deliveryLogs 


--insert web.deliveryLogs(empid, divisionid, custid)
select org.person_id('Федоров А. Н.'), org.division_id('08 ФАНФАН'), cust.customer_id('9167834248')
select SCOPE_IDENTITY() ident


select * from web.deliveryLogs order by 1 desc
select top 1 logid from web.deliveryLogs order by 1 desc





