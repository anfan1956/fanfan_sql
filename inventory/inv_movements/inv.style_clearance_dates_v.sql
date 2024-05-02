USE [fanfan]
GO

/****** Object:  View [inv].[style_clearance_dates_v]    Script Date: 02.05.2024 23:23:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER view [inv].[style_clearance_dates_v] as
with _barcodes as (
	select b.barcodeID, b.styleID
	from inv.barcodes b
)
, _sorted (receipt_date, styleid, num) as (
	select t.transactiondate, b.styleID, ROW_NUMBER() over(partition by b.styleid order by t.transactiondate) num
	from inv.inventory i
		join inv.transactions t on t.transactionID=i.transactionID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join _barcodes b on b.barcodeID=i.barcodeID
	where tt.transactiontypeID in (inv.transactiontype_id('WAREHOUSE CLEARANCE'), inv.transactiontype_id('WAREHOUSE CLEARANCE LOCAL'), 
	inv.transactiontype_id('Consignment')	)
)
select receipt_date, styleid
from _sorted where num=1

GO
declare @styleid int =21647

select * 
from inv.style_clearance_dates_v v where v.styleid=@styleid;

