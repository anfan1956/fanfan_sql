USE [fanfan]
GO
 
ALTER function [inv].[barcode_avail2_f] (@barcodeid int) returns table as return
with _barcodes (barcodeid) as (
	select b.barcodeID 
		from inv.barcodes b
			join inv.inventory i on i.barcodeID=b.barcodeID
		where styleid = (select styleID from inv.barcodes where barcodeID =@barcodeid )		
			and i.logstateID =8
		group by b.barcodeID			
		having sum(i.opersign)>0
)
, _lastTran (barcodeID, lastTranID) as (
	select 
		i.barcodeID, max(i.transactionid)
	from inv.inventory i
		join _barcodes b on b.barcodeid=i.barcodeID
	group by i.barcodeID
)
, _price ( price, discount) as (
	select top 1 price, discount 
	from inv.pricesets ps
		join inv.prices p on p.pricesetID = ps.pricesetID
	order by p.pricesetID desc
)
select 
	b.barcodeid, bp.styleID, bp.size размер,  bp.color цвет, 
	d.divisionfullname магазин, 
	p.price цена, 
	p.discount скидка, 
	bp.brand марка,
	bp.category категория, 
	bp.article артикул, 
	bp.season сезон
from _barcodes b
	join _lastTran lt on lt.barcodeID=b.barcodeid
	join inv.inventory i on 
		lt.barcodeID=i.barcodeid and 
		i.transactionID = lt.lastTranID 
		and i.opersign =1
	join org.divisions d on d.divisionID=i.divisionID
	cross join _price p
	cross apply inv.barcode_props_ (b.barcodeid) bp
go


declare @barcodeid int = 667746;
select * from inv.barcode_avail2_f(@barcodeid) order by 1;


