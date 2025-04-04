USE [fanfan]
GO

if OBJECT_ID('inv.brandStyles_avail_f')  is not null drop function inv.brandStyles_avail_f
go

create function inv.brandStyles_avail_f(@brandid int) returns table as return
	with _discounts (styleid, price, discount, num) as (
		select p.styleID, price, p.discount, ROW_NUMBER() over (partition by p.styleid order by p.pricesetid desc)
		from inv.prices p
			join inv.pricesets ps on ps.pricesetID=p.pricesetID
	)
	, _styles_photos (parent_styleid, photo) as (
		select parent_styleid, 'yes' 
		from inv.styles_photos 
		group by parent_styleid
	)
	select 
		it.inventorytyperus категория,
		s.article артикул, 
		s.styleID модель,
		sp.photo,
		se.season сезон, 
		s.cost закупка, 
		s.currencyID валюта, 
		round(d.price, -1
			) цена,
		d.discount  скидка
		, isnull (pd.discount, 0) промо
	from inv.inventory i
		join inv.barcodes b on b.barcodeID= i.barcodeID
		join inv.styles s on s.styleID=b.styleID
		join inv.styles sr on sr.styleID=s.parent_styleid
		join inv.brands br on br.brandID=s.brandID
		left join inv.orders o on o.orderID= sr.orderID
		join inv.seasons se on se.seasonID =sr.seasonID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		join _discounts d on d.styleid=s.styleID and d.num=1
		left join web.promo_styles_discounts pd on pd.styleid = s.styleID
		left join _styles_photos sp on sp.parent_styleid=s.parent_styleid		
		left join inv.current_rate_v r on r.currencyid=o.currencyID and r.divisionid= org.division_id('FANFAN.STORE')
	where i.logstateID = inv.logstate_id('in-warehouse')
		and s.brandID=@brandid
	group by 
		s.styleID,
		s.article, 
		sp.photo, 
		se.season, 
		s.cost, 
		s.currencyID, 
		it.inventorytyperus, 
		d.discount, pd.discount, 
		sr.cost, sr.cost_adj, r.rate, r.markup, 
		o.orderclassID, 
		d.price
	having sum(i.opersign)>0
go

select * from inv.brandStyles_avail_f(103) 
where артикул = '47571/3099'
order by 1,  4, 2
