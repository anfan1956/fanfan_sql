if OBJECT_ID('web.address_register_json') is not null drop proc web.address_register_json
go
create proc web.address_register_json @json varchar(max) as
set nocount on;
begin try
	begin transaction;

	declare 
		@phone char(10), 
		@Session varchar(max), 
		@action varchar(max), 
		@fio varchar(max), 
		@address varchar(max), 
		@ticketid varchar(max), 
		@receiver_phone char(10)
	declare			
		@custid int ;

	with s (phone, Session, action, fio, address, ticketid, receiver_phone) as (
		select phone, Session, action, fio, address, ticketid, receiver_phone
		from OPENJson(@json)
			with(
				phone char(10) '$.phone', 
				Session varchar(max) '$.Session', 
				action varchar(max) '$.action', 
				fio varchar(max) '$.fio', 
				address varchar(max) '$.address', 
				ticketid varchar(max) '$.ticketid', 
				receiver_phone char(10) '$.receiver_phone'
			) as jsvalues
		)
--		select * from s
	, t1 as (
			select phone, Session, action, fio, address, ticketid, receiver_phone 
			from s
			where phone is not null)
	, t2 as (
			select phone, Session, action, fio, address, ticketid, receiver_phone 
			from s
			where phone is null)
	select 	
		@phone= t1.phone, @Session= t1.Session, @action = t1.action, 
		@fio = t2.fio, @address = t2.address, @ticketid =  t2.ticketid, @receiver_phone= t2.receiver_phone 
	from  t1 cross apply t2;
--	select @phone phone, @Session Session, @action action, @fio fio, @ticketid tickedid, @receiver_phone receiver_phone, @address address;

	with s (address_string) as (select @address)
	merge web.deliveryAddresses as t using s
	on t.address_string=s.address_string
	when not matched then 
	insert (address_string) values (address_string); 

	with s (phone, fio) as (select @receiver_phone, @fio)
	merge web.receiver_phones as t using s
	on t.phone=s.phone
	when matched and @fio <> '' and t.fio<>s.fio then
		update set t.fio = s.fio
	when not matched then 
		insert (phone, fio) values (phone, fio); 


	declare @addressid int;
	select @addressid = a.addressid from web.deliveryAddresses a 
	where a.address_string=@address;
--	select @addressid addressid;

	declare @phoneid int;
	select @phoneid = a.phoneid from web.receiver_phones a 
	where a.phone=@receiver_phone;


	select @custid = cust.customer_id(@phone);
	with s (custid, addressid, receiver_phoneid) as (select @custid, @addressid, @phoneid)
	merge web.customer_spots as t using s
		on t.custid= s.custid
		and	t.addressid= s.addressid
		and t.receiver_phoneid=s.receiver_phoneid
	when not matched then 
		insert (custid, addressid, receiver_phoneid)
		values (custid, addressid, receiver_phoneid)

		;

	declare @spotid int = (select spotid from web.customer_spots where custid=@custid and addressid= @addressid and receiver_phoneid=@phoneid)
	--select @spotid
	select 
		s.spotid, a.address_string, p.phone, p.fio
	from web.customer_spots s
		join web.deliveryAddresses a on a.addressid=s.addressid
		join web.receiver_phones p on p.phoneid=s.receiver_phoneid
	where s.spotid =@spotid
	for json path


	--; throw 50001, 'no proc debuggin', 1
	commit transaction
end try
begin catch
	select ERROR_MESSAGE(), ERROR_LINE()
	rollback transaction
end catch
go


if OBJECT_ID('web.delivery_addr_js_') is not null drop function web.delivery_addr_js_
go 
create function web.delivery_addr_js_(@phone char(10)) returns varchar(max) as 
	begin;
		declare @adr varchar(max);
;with s as (
select 
	s.spotid ,a.address_string, ROW_NUMBER() over(partition by a.address_string order by spotid desc) n
from web.customer_spots s
	join web.deliveryAddresses a on a.addressid=s.addressid
where s.custid= cust.customer_id(@phone)
)
select @adr = (select * from  (
select spotid, s.address_string
from s 
where n =1
union 
select 0, 'добавить адрес'
) as js order by 1 desc for json path);
		return @adr
	end
go

declare @json varchar(max);
select @json =
	--'[{"phone": "9167834248", "Session": "e23e2ffe-30bf-40b5-9d1f-bf5b8a1e7093", "action": "use"}, 
	--{"fio": "Федоров Александр Николаевич", "receiver_phone": "9637633465", "address": "г Москва, ул Крылатские Холмы, д 30 к 7, кв 75", "ticketid": "37"}]'
--	'[{"phone": "9167834248", "action": "use"}, {"fio": "Федоров Александр Николаевич", "phone": "+79637633465", "address": "г Москва, ул Крылатские Холмы, д 30 к 7, кв 75", "ticketid": ""}]'
'[{"phone": "9167834248", "action": "use"}, {"fio": "Федоров Александр Николаевич", "receiver_phone": "+796937633465", "address": "г Москва, ул Крылатские Холмы, д 30 к 7, кв 75", "ticketid": ""}]'


--exec web.address_register_json @json; 

declare @phone char(10) = '9167834248'
select web.delivery_addr_js_(@phone)

--select * from web.deliveryAddresses ;select * from web.receiver_phones
;with s as (
select 
	s.spotid ,a.address_string, ROW_NUMBER() over(partition by a.address_string order by spotid desc) n
from web.customer_spots s
	join web.deliveryAddresses a on a.addressid=s.addressid
where s.custid= cust.customer_id(@phone)
)
select 0 spotid, 'добавить адрес' address_string
union 
select spotid, s.address_string
from s 
where n =1
order by 1 desc
for json path




select * from web.deliveryAddresses