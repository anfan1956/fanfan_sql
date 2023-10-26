if object_id('web.customer_orders_json') is not null drop function web.customer_orders_json
go
create function web.customer_orders_json (@json varchar(max)) returns varchar(max) as 
	begin
		declare @orders varchar(max);
		with s (phone) as (
			select phone from 
			openjson(@json)
			with (
				phone char(10) '$.phone'
			) as jsonValues
		)
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
			cross apply s
		where w.[телефон клиента]=s.phone
		group by orderid, [дата заказа], [склад получения]
		order by orderid desc
		for json path);
		if @orders is null select @orders = (select 'У вас нет размещенных заказов' информация for json path)
		return @orders
	end
go


declare @json varchar(max) = '{"phone":"9167834248"}'

select web.customer_orders_json (@json);

with s (phone) as (
	select phone from 
	openjson(@json)
	with (
		phone char(10) '$.phone'
	) as jsonValues
)
			select orderid [№ заказа], 
			format([дата заказа], 'dd.MM.yyyy') дата , 
			format([дата заказа], 'HH:MM') время, 
			case [склад получения]
				when 'доставка'  then 'доставка'
				else 'самовывоз' end 'способ доставки',
			format(sum(оплачено), '#,##0 руб') оплачено, 
			'в работе' статус
		from inv.webOrders_toShip_v w
			cross apply s
		where w.[телефон клиента]=s.phone
		group by orderid, [дата заказа], [склад получения]
		order by orderid desc
--select * from s;	