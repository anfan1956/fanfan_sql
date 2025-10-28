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
	select  i.transactionID, t.transactiondate, i.barcodeID
		from inv.inventory i
		join inv.transactions t on t.transactionID=i.transactionID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	where 1=1
		and tt.transactiontype in ('order', 'ORDER LOCAL', 'consignment' )
		and i.opersign =1
)
select 
	i.barcodeid
	, i.logstateID
	, s.orderid
	, oc.orderclassID
	, o.showroomID
	, o.currencyID
	, o.orderdiscount
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
	, src1.transactiondate 
	, coalesce (s.gender, o.gender, 
		case 
			when o.buyerid in (178, 187, 186, 177) then 'm'
			else 'f'
		end
		) as gender
from inv.inventory i
	join inv.barcodes b on b.barcodeID= i.barcodeID
	join inv.styles s on s.styleID=b.styleID
	left join inv.orders o on o.orderID=s.orderID
	left join inv.orderclasses oc on oc.orderclassID=o.orderclassID
	
	cross apply (
		select top 1 
		src.transactiondate 
		from src
		where src.barcodeID= i.barcodeID
		order by 1 desc
	) as src1
group by 
	i.barcodeID, 
	s.orderID
	, oc.orderclassID
	, o.currencyID, 
	i.logstateID, 
	o.showroomID,
	o.orderdiscount, 
	s.retail, 
	o.buyerID, 
	s.brandID, s.seasonID, s.inventorytypeID
	, s.gender, o.gender
	, s.styleID
	, b.colorID
	, b.sizeID
	, s.sizegridID
	, s.cost 
	, src1.transactiondate

having sum(i.opersign)>0
GO

DECLARE @startDate DATE = '20251008'
	, @barcodeid int  = 664226;

select * from inv.barcode_info_v v  -- where v.barcodeid=@barcodeid -- count = 137521

select top 5 c.contractor,  o.* from inv.orders  o
	join org.contractors c on c.contractorID = o.buyerID
order by 1 desc
select top 5 * from inv.styles s order by 1 desc
select distinct buyerid, contractor 
	from inv.orders o
	join org.contractors c on c.contractorID = o.buyerID