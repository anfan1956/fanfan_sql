
if OBJECT_ID('web.barcodes_discounts_') is not null drop function web.barcodes_discounts_
go
create function web.barcodes_discounts_(@info dbo.barcodes_list readonly) returns table as return

select b.barcodeID, d.discount
from web.promo_styles_discounts d	
	join web.promo_events e on e.eventid=d.eventid
	join inv.barcodes b on b.styleID=d.styleID
	join @info i on i.barcodeID=b.barcodeID
where 
	e.eventClosed ='False' 
	and cast(getdate() as date) between e.datestart and e.datefinish
go

declare @info dbo.barcodes_list; insert @info values (655067), (665846);
select barcodeID, discount from web.barcodes_discounts_(@info)
