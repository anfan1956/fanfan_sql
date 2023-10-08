declare @phone char(10) = '9167834248'
select * from inv.site_reservations
select * from web.delivery_logs

select * from web.customer_spots
--select * from web.deliveryAddresses
select * from web.active_orders_v
declare @top_addr varchar(max);



if OBJECT_ID('web.top_adr_') is not null drop function web.top_adr_
go
create function web.top_adr_ (@phone char(10)) returns varchar(max) as 
begin
declare @top_addr varchar(max)

select @top_addr = (select * from   (
select top 1 spotid, a.address_string
from web.customer_spots s
	join web.deliveryAddresses a on a.addressid = s.addressid
where s.custid = cust.customer_id(@phone)
order by 1 desc
union
select 0  spotid, 'добавить адрес' address_string
) as js order by 1 desc  for json path)

return @top_addr
end 
go
declare @phone char(10) = '9167834248'
select web.top_adr_ (@phone)
