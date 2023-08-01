select * from web.deliveryLogs

select d.*

--update d set d.addressid= null, recipient=null, recipient_phone=null
from web.deliveryLogs d
	join (select top 1 * from web.deliveryLogs d order by 1 desc) as o on o.logid = d.logid

--select web.ticket_address_(9)

if OBJECT_ID('web.delivery_addr_') is not null drop function web.delivery_addr_
go

create function web.delivery_addr_ (@logid as varchar (max)) returns varchar(max) as
begin
	declare @adr varchar(max);
SELECT @adr =  CONCAT_WS( ';', d.logid, d.recipient, d.recipient_phone, a.address_string)
	--logid, d.recipient, d.recipient_phone, a.address_string
from web.deliveryLogs d 
	join web.deliveryAddresses a on a.addressid=d.addressid
	where d.logid = @logid
return @adr
end 
go

select web.delivery_addr_(13)
select бренд, категория, amount from web.active_orders_v where id_заказа = 78139
