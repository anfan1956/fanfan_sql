if OBJECT_ID ('inv.storageBoxContent_') is not null drop view inv.storageBoxContent_
go 
create view inv.storageBoxContent_ as
with _sb as (
select 
	sb.ID, sb.barcodeID 
from inv.storage_box sb
group by sb.ID, sb.barcodeID
having sum(sb.opersign) =1
)
select 
		sb.ID boxID
		, br.brand
		, inventorytype category
		, st.article
		, c.color
		, sz.size
		, se.season
		, st.orderID
		, cr.currencycode CUR
		, st.cost
		, pr.price retail
		, pr.discount
		, sb.barcodeID	 
from _sb sb	
	join inv.barcodes b on b.barcodeID  = sb.barcodeID
	join inv.styles st on st.styleID = b.styleID
	join inv.brands br on br.brandID= st.brandID
	join inv.inventorytypes it on it.inventorytypeID=st.inventorytypeID
	join inv.colors c on c.colorID = b.colorID
	join inv.sizes sz on sz.sizeID = b.sizeID
	join inv.seasons se on se.seasonID=st.seasonID
	join inv.orders o on o.orderID=st.orderID
	join cmn.currencies cr on cr.currencyID = o.currencyID
	outer apply (
		select top 1 p.price, p.discount
			from inv.prices p 
			where p.styleID = st.styleID
			order by p.pricesetID desc
	) pr
go

declare @info dbo.barcodes_list; insert @info values (582714), (582713), (664008); 
--where sb.ID = 5
select * 
from inv.storageBoxContent_ where boxID = 5