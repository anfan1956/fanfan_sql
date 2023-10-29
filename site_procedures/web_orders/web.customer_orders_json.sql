if object_id('web.customer_orders_json') is not null drop function web.customer_orders_json
go
create function web.customer_orders_json (@json varchar(max)) returns varchar(max) as 
	begin
		declare @orders varchar(max), @phone char(10);
		with s (phone) as (
			select phone from 
			openjson(@json)
			with (
				phone char(10) '$.phone'
			) as jsonValues
		)
		select @phone = phone from s;
		select @orders = (
			select orderid [№ заказа], 
			format([дата заказа], 'dd.MM.yyyy') дата , 
			format([дата заказа], 'HH:MM') время, 
			case [склад получения]
				when 'доставка'  then 'доставка'
				else 'самовывоз' end 'способ доставки',
			format(sum(оплачено), '#,##0 руб') оплачено, 
			'в работе' статус
		from inv.webOrders_toShip_v w
--		where w.[телефон клиента]=s.phone
		where w.custid = cust.customer_id( @phone)
		group by orderid, [дата заказа], [склад получения]
		order by orderid desc
		for json path);
		if @orders is null select @orders = (select 'У вас нет размещенных заказов' информация for json path)
		return @orders
	end
go


declare @json varchar(max) = '{"phone":"9167834248"}'

select web.customer_orders_json (@json);
declare @phone char(10);

with s (phone) as (
	select phone from 
	openjson(@json)
	with (
		phone char(10) '$.phone'
	) as jsonValues
)
select @phone = phone from s;


select 
	orderid [№ заказа], 
	format([дата заказа], 'dd.MM.yyyy') дата , 
	format([дата заказа], 'HH:MM') время, 
	case [склад получения]
		when 'доставка'  then 'доставка'
		else 'самовывоз' end 'способ доставки',
	--format(sum(оплачено), '#,##0 руб') оплачено, 
	'в работе' статус
from inv.webOrders_toShip_v w
--where w.[телефон клиента]=@phone
where w.custid = cust.customer_id( @phone)
group by orderid, [дата заказа], [склад получения]
order by orderid desc
--select * from s;	