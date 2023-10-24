if OBJECT_ID('web.order_delivery_json') is not null drop function web.order_delivery_json
go 
create function web.order_delivery_json(@json varchar(max)) returns varchar(max) as 
begin 
	declare @details varchar(max);

	with s (orderid ) as (
	select orderid from openjson (@json)
		with (
			orderid int '$.orderid'
		) as jsonvalues
	)
select @details=(
	select
		a.address_string адрес, d.divisionfullname магазин, 
		p.fio имя, 
		isnull(p.phone, cust.prime_phone_f(r.custid)) телефон, 
		code код 
	from inv.site_reservations r
		join web.delivery_logs l on l.orderid=r.reservationid
		left join web.customer_spots c on c.spotid = l.spotid
		left join web.deliveryAddresses a on a.addressid=c.addressid
		left join web.receiver_phones p on p.phoneid=c.receiver_phoneid
		left join org.divisions d on d.divisionID = pickupDivId
		join s on s.orderid = l.orderid
	for json path
)

return @details
end 
go

declare @json varchar(max)='{"orderid": 79404 }'
declare @orderid int = 79404
select web.order_details_json(@json)
select web.order_delivery_json(@json)