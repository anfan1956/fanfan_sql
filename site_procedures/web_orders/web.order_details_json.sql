if OBJECT_ID('web.order_details_json') is not null drop function web.order_details_json
go 
create function web.order_details_json(@json varchar(max)) returns varchar(max) as 
begin 
	declare @details varchar(max);

	with s (orderid ) as (
	select orderid from openjson (@json)
		with (
			orderid int '$.orderid'
		) as jsonvalues
	)
		select @details =(select
--			r.reservationid orderid,
			p.brand марка, 
			p.category категория, 
			p.styleID модель, 
			p.article артикул, 
			p.color цвет,
			p.size размер,
			sg.barcodeID баркод, 
			cast(round(sg.amount, 0) as int) стоимость
		from inv.site_reservations r 
			join inv.sales_goods sg on sg.saleID=r.saleid
			cross apply inv.barcode_props_(sg.barcodeID) p
			join s on s.orderid=r.reservationid
		for json path);
		select @details  = isnull(@details, 
		(select 'заказ с таким номером не существует' error for json path))
	return @details
	end 
go

declare @json varchar(max)='{"orderid": 79404 }'
declare @orderid int = 79404
select web.order_details_json(@json)
select web.order_delivery_json(@json)