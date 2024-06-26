USE [fanfan]
GO
 
ALTER function [inv].[barcode_avail2_f] (@barcodeid int) returns table as return
with 
	cte (styleid, price, discount, num) as (
		select p.styleID, p.price, p.discount, ROW_NUMBER() over (partition by p.styleid order by p.pricesetid desc)
		from inv.prices p 
	)
, s(styleid, currencyid, cost, brand, category, article, season, orderclassID) as (
	select 
		b.styleID, 
		o.currencyID, 
		s.cost * isnull(s.cost_adj, 1), 
		brand, 
		it.inventorytyperus, 
		s.article, se.season, 
		o.orderclassID
	from inv.barcodes b
		join inv.styles s on s.styleid=b.styleID
		join inv.orders o on o.orderID=s.orderID
		join inv.brands br on br.brandID=s.brandID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		join inv.seasons se on se.seasonID=o.seasonID
	where b.barcodeID=@barcodeid
)
, f (barcodeid, styleID, размер, цвет, магазин, цена, скидка, марка, категория, артикул, сезон)
	as (
select 
	b.barcodeID, 
	b.styleID, 
	sz.size, 
	c.color, 
	d.divisionfullname, 
	--case orderclassID
	--	when 3 then cte.price 
	--	else r.markup*r.rate* s.cost end price, 	
	round(cte.price, -1) price,
	cte.discount, 
	s.brand, 
	category, 
	s.article, 
	s.season
from inv.barcodes b
	join s on s.styleid=b.styleID	
	join inv.barcodes_location_v l on l.barcodeID=b.barcodeID
	join inv.sizes sz on sz.sizeID=b.sizeID
	join inv.colors c on c.colorID=b.colorID
	join org.divisions d on d.divisionID=l.divisionID
	left join inv.current_rate_v r on r.divisionid=l.divisionid and r.currencyid = s.currencyid
	left join cte on cte.styleid=s.styleid and cte.num =1
	)
select * from f
go


declare @barcodeid int =
--	663776
	667789

select * from inv.barcode_avail2_f(@barcodeid)
select * from inv.barcodes_location_v where barcodeid = @barcodeid;
with s (styleid) as 
(
	select styleID
	from inv.barcodes b 
	where b.barcodeID= @barcodeid

)
select 
	b.barcodeID
from inv.barcodes b
	join s on s.styleid=b.styleID


