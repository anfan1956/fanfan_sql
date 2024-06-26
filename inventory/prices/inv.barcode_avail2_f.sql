USE [fanfan]
GO
/****** Object:  UserDefinedFunction [inv].[barcode_avail2_f]    Script Date: 01.09.2022 22:44:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [inv].[barcode_avail2_f] (@barcodeid int) returns table as return
with _s (article, brandid, cost, currencyid, inventorytypeid, seasonid) as (
	select s.article, s.brandID, s.cost * ISNULL(s.cost_adj, 1), 
		o.currencyid, s.inventorytypeID, s.seasonID
	from inv.barcodes b 
		join inv.styles s on s.styleID=b.styleID
		join inv.orders o on o.orderid = s.orderid
	where b.barcodeID=@barcodeid
)
, _barcodes (barcodeid, styleid, colorid, inventorytypeid, sizeid, cost, currencyid, article, brandid, seasonid) as (
	select distinct b.barcodeid, st.styleID, b.colorID, s.inventorytypeID,
		b.sizeID, s.cost, s.currencyid, s.article, s.brandID, s.seasonID
	from inv.styles st
		join _s s on s.article=st.article and s.brandID=st.brandID
		join inv.barcodes b on b.styleid=st.styleid
) 
, f as (
	select b.barcodeid, b.styleid, b.colorid, b.sizeid, 
		isnull(b.cost * r.rate * r.markup, 0) price, b.seasonID,
		i.divisionid, b.article, b.brandID, b.inventorytypeID
	from _barcodes b
		join inv.inventory i on i.barcodeid = b.barcodeid
		join inv.logstates l on l.logstateid = i.logstateid
		left join inv.current_rate_v r on r.divisionid=i.divisionid and r.currencyid = b.currencyid
	where l.logstateid  in (8) and i.divisionid <> 0
	group by b.barcodeid, b.styleid, b.colorid, b.sizeid, b.brandID, b.seasonID,
		i.divisionid, b.cost, b.article, r.rate, r.markup, b.inventorytypeID
	having sum(i.opersign)>0
)
, _discount(styleid, discount, num) as (
	select  
		s.styleID,
		p.discount, 
		ROW_NUMBER() over (partition by s.styleid order by p.pricesetid desc)
	from inv.prices p
		join inv.styles s on s.styleID=p.styleID
		join inv.barcodes b on b.styleID=s.styleID
	where b.barcodeID= @barcodeid
)
select f.barcodeid, d.division магазин, f.article артикул, 
	b.brand марка, f.styleID, c.color цвет, s.size размер, 
	it.inventorytyperus категория, se.season сезон, f.price цена
	, ds.discount скидка
from f
	join inv.colors c on c.colorid = f.colorid
	join inv.sizes s on s.sizeid = f.sizeid
	join org.divisions d on d.divisionID=f.divisionID
	join inv.brands b on b.brandID=f.brandID
	join inv.inventorytypes it on it.inventorytypeID=f.inventorytypeID
	join inv.seasons se on se.seasonID=f.seasonID
	join _discount ds on ds.styleid= f.styleid
where ds.num=1
go 

declare @barcodeid int = 659054
select *  from inv.barcode_avail2_f(@barcodeid);


with _discount(barcodeid, discount, num) as (
	select  
		b.barcodeID, 
		p.discount, 
		ROW_NUMBER() over (partition by s.styleid order by p.pricesetid desc)
	from inv.prices p
		join inv.styles s on s.styleID=p.styleID
		join inv.barcodes b on b.styleID=s.styleID
	where b.barcodeID= @barcodeid

)
select * from _discount d where d.num=1