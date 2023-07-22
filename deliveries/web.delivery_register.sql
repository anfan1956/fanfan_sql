if OBJECT_ID('web.delivery_register') is not null drop proc web.delivery_register
go
create proc web.delivery_register 
	@address_string varchar(max), 
	@log varchar(max), 
	@fio varchar(100), 
	@phone char(10), 
	@note varchar(max) output
as

set nocount on;
begin try
	begin transaction;
	if (@log = 'undefined') throw 50001, 'неопределен номер поставки. Аборт', 1;

	declare @logid int = cast (@log as int);


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