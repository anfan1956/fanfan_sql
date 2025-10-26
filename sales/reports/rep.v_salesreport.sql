USE [fanfan]
GO

/****** Object:  View [rep].[v_salesreport]    Script Date: 26.10.2025 20:27:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER view [rep].[v_salesreport]
as
	select	dbo.justdate( t.transactiondate )				AS date,			
			format( t.transactiondate, 't', 'RU')			AS time,
			rt.r_type_rus									AS pmtType,
			datepart( dd, t.transactiondate )				as day,
			datepart( hh, t.transactiondate )				as hour, 
			datepart( mm, t.transactiondate )				as month, 
			datepart( yy, t.transactiondate )				as year,
			replace( d.divisionfullname, ' OLD', '' )		as shop,
			tt.transactiontype								as operation, 
			[sg].[saleID], [sg].[barcodeID], [sg].[amount], [sg].[price], [sg].[client_discount] as [client_dsc], [sg].[barcode_discount] as [manual_dsc],
			g.baseprice, g.discount as discount,
			sg.amount / cmn.ratedate( cast( t.transactiondate as date ), 978 ) as amountEUR,
			sg.price / cmn.ratedate( cast( t.transactiondate as date ), 978 ) as priceEUR,
			s.customerID, 
			cust.customer_fullname( s.customerID ) as customer,
			isnull( p.lfmname, 'unknown' ) as saleperson, 
			g.brand, 
			g.styleID, g.article, g.cost, g.color, g.size, g.season, g.composition, g.origin,
			g.category,
			ch.chain
	from inv.sales_goods (nolock) sg
		join inv.sales (nolock)  s on s.saleID = sg.saleID
		join inv.transactions (nolock) t on t.transactionID = s.saleID
		join inv.transactiontypes (nolock) tt on tt.transactiontypeID = t.transactiontypeID
		join org.divisions (nolock) d on d.divisionID = s.divisionID
		join org.chains (nolock) ch on ch.chainID = d.chainID
		left join inv.v_goods g on g.barcodeID = sg.barcodeID
		left join org.persons (nolock) p on p.personID = s.salepersonID
		join inv.sales_receipts sr on sr.saleID = s.saleID
		join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
GO


select top 50 * from  [rep].[v_salesreport] order by 1 desc 

select top 10 * from inv.sales_receipts sr order by 1 desc;