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
		declare @logid int;
		declare @addresid int;
	
		if (@log = 'undefined')  
			begin
				select @note = (select 'неопределен номер поставки' fail for json path)
			end 	
		else
			begin
				select @logid = cast (@log as int);

				with s (address_string)  as (
					select @address_string
				)
				merge web.deliveryAddresses as t using s
				on t.address_string = s.address_string
				when not matched 
					and s.address_string<>''
				then 
				insert (address_string)
				values(address_string);
	
				select @addresid = a.addressid from web.deliveryAddresses a 
				where a.address_string=@address_string;

				if exists (select * from web.deliveryLogs where logid=@logid)
					begin			
						if @address_string<>'' and @fio <>'' and @phone <> ''
							begin
								update l set l.addressid=@addresid, l.recipient_phone=@phone, l.recipient=@fio
								from web.deliveryLogs l where l.logid=@logid;
								select @note =  web.ticket_address_(@logid)
							end
						else 
							begin
								select @note = (select 'no delivery data' fail for json path)
							end
					end
				else
					begin
						select @note = (select 'logid does not exist' fail for json path)
					end
			end
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
	@logid int = 1;
select @address = 'г Москва, Ленинский пр-кт, д 52, кв 44';
--exec web.delivery_register @address, @logid, @fio, @note output; select @note;
go	
--set nocount on; declare @note varchar(max); exec web.delivery_register 'г Москва, Ленинский пр-кт, д 52, кв 431', '2', 'Федорова Ирина Владимировна', '', @note output; select @note;

select * from web.deliveryAddresses
if OBJECT_ID('web.ticket_address_') is not null drop function web.ticket_address_
go
create function web.ticket_address_(@ticketid int ) returns varchar (max) as 
	begin
		declare @add_string varchar(max);
		select @add_string= (
			select recipient, recipient_phone phone, a.address_string addr, d.logid 
			from web.deliveryLogs d 
				join web.deliveryAddresses a on a.addressid=d.addressid
		where d.logid=@ticketid		
				for json path)
		return @add_string
	end
go
select web.ticket_address_('11')


select l.*, a.address_string from web.deliveryLogs l left join web.deliveryAddresses a on a.addressid= l.addressid order by 1 desc

set nocount on; declare @note varchar(max); exec web.delivery_register '', '23', '', '', @note output; select @note;