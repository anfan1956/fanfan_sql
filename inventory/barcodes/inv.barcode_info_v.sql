USE [fanfan]
GO

/****** Object:  View [inv].[barcode_info_v]    Script Date: 08.10.2025 17:36:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER view inv.barcode_info_v as

with src as 
(
	select i.transactionID, t.transactiondate, i.barcodeID
		from inv.inventory i
		join inv.transactions t on t.transactionID=i.transactionID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	where tt.transactiontype in ('order', 'ORDER LOCAL', 'consignment' )
)
select i.barcodeid, i.logstateID, s.orderid, o.currencyID, 	 
	o.orderdiscount
	, s.retail
	,o.buyerID as clientid
	, s.brandID
	, s.seasonID
	, s.inventorytypeID
	, s.styleID
	, b.colorID
	, b.sizeID
	, s.sizegridID
	, s.cost
	, src.transactiondate 
from inv.inventory i
	join inv.barcodes b on b.barcodeID= i.barcodeID
	join inv.styles s on s.styleID=b.styleID
	join src on src.barcodeID=i.barcodeID
	left join inv.orders o on o.orderID=s.orderID
--where i.barcodeID = @barcodeid	
group by 
	i.barcodeID, 
	s.orderID,
	o.currencyID, 
	i.logstateID, 
	o.orderdiscount, 
	s.retail, 
	o.buyerID, 
	s.brandID, s.seasonID, s.inventorytypeID, s.styleID, 
	b.colorID
	, b.sizeID
	, s.sizegridID
	, s.cost 
	, src.transactiondate

having sum(i.opersign)>0
GO


