USE [fanfan]
GO
 
ALTER function [inv].[barcode_avail2_f] (@barcodeid int) returns table as return
with _barcodes (barcodeid, divisionid, styleid, colorid, sizeid) as (
	select b.barcodeID
		, i.divisionID, b.styleID, b.colorID, b.sizeID
		from inv.barcodes b
			join inv.inventory i on i.barcodeID=b.barcodeID
		where b.styleid = (select styleID from inv.barcodes where barcodeID =@barcodeid )		
			and i.logstateID =8
		group by 
			b.barcodeID, b.styleID, i.divisionID, b.colorID, b.sizeID
		having sum(i.opersign)>0
)
, _boxes (barcodeId, boxID) as (
	select sb.barcodeID, sb.boxID
	from inv.storage_box sb 
	group by sb.barcodeID, sb.boxID
	having sum(sb.opersign)>0
	)
select 
	b.barcodeid
	, b.styleID
	, sz.size размер
	, c.color цвет
	, d.divisionfullname магазин
	, boxID
	, pr.price цена
	, pr.discount скидка 
	, br.brand  марка
	, it.inventorytype категория
	, st.article артикул
	, se.season сезон
from _barcodes b
	join inv.styles st on st.styleID = b.styleid
	join inv.colors c on c.colorID=b.colorid
	join inv.sizes sz on sz.sizeID=b.sizeid
	join org.divisions d on d.divisionID=b.divisionid
	join inv.brands br on br.brandID=st.brandID
	join inv.seasons se on se.seasonID=st.seasonID
	join inv.inventorytypes it on it.inventorytypeID=st.inventorytypeID
	left join _boxes bx on bx.barcodeId=b.barcodeid
	cross apply (
		select top 1 price, discount
		from inv.prices p
			join inv.pricesets ps on ps.pricesetID=p.pricesetID
			where p.styleID=b.styleid
			order by p.pricesetID desc
	) as pr
go


declare @barcodeid int = 634045;
--select * from inv.barcode_avail2_f(@barcodeid) order by 1;

--select * from inv.prices p join inv.pricesets ps on ps.pricesetID = p.pricesetID where styleID =17718


select *  from inv.barcode_avail2_f(584694)
