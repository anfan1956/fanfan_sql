if OBJECT_ID('web.delivery_logs') is not null drop table web.delivery_logs
if OBJECT_ID('web.customer_spots') is not null drop table web.customer_spots
if OBJECT_ID('web.receiver_phones') is not null drop table web.receiver_phones
go 
create table web.receiver_phones (
	phoneid int not null identity primary key,
	phone char(10) not null
)


create table web.customer_spots (
	spotid int not null identity primary key,
	custid int not null foreign key references cust.persons(personid), 
	addressid int not null foreign key references web.deliveryAddresses(addressid), 
	receiver_phoneid int not null foreign key references web.receiver_phones (phoneid)
	,	unique (custid, addressid, receiver_phoneid)
)



create table web.delivery_logs (
	parcelid int not null identity primary key, 
	orderid int not null foreign key references inv.transactions(transactionid), 
	barcodeid int not null foreign key references inv.barcodes(barcodeid), 
	addressid int not null foreign key references cust.persons(personid), 
	code varchar(6) null, 
	dateDeliverd datetime null, 
	unique (orderid, barcodeid, addressid)
)

go 
select * from inv.site_reservations