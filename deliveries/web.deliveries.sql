
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

if OBJECT_ID('web.delivery_register') is not null drop proc web.delivery_register
go
create proc web.delivery_register 
	@address_string varchar(max), 
	@logid int, 
	@fio varchar(100), 
	@phone char(10), 
	@note varchar(max) output
as

set nocount on;
begin try
	begin transaction;

	declare @addresid int;
	with s (address_string)  as (
		select @address_string
	)
	merge web.deliveryAddresses as t using s
	on t.address_string = s.address_string
	when not matched then 
		insert (address_string)
		values(address_string);
	
	select @addresid = a.addressid
	from web.deliveryAddresses a 
	where a.address_string=@address_string;

	update l set l.addressid = @addresid, l.recipient = @fio, l.recipient_phone=@phone
	from web.deliveryLogs l
	where l.logid= @logid;

	select @note= 'logid updated with addressid ' + cast(@addresid as varchar(max))
	
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction;
end catch
	
go

declare 
	@address varchar(max), 
	@note varchar (max), 
	@fio varchar(100) = 'Федоров Иван Александрович', 
	@logid int =1;
select @address = 'г Москва, Ленинский пр-кт, д 52, кв 44';
--exec web.delivery_register @address, @logid, @fio, @note output; select @note;
go	
set nocount on; declare @note varchar(max); exec web.delivery_register 'г Москва, Ленинский пр-кт, д 52, кв 431', '42', 'Федорова Ирина Владимировна', '9857278054', @note output; select @note;

select * from web.deliveryAddresses
select * from web.deliveryLogs



