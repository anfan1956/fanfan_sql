USE [fanfan]
GO

/****** Object:  UserDefinedFunction [inv].[orderHeader_]    Script Date: 29.01.2024 3:10:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER function [inv].[orderHeader_] (@orderid int) returns table as return

with _division (division, qty, amount) as (
	select  d.divisionfullname, sum(i.opersign), sum(cost)
	from inv.inventory i
		join inv.barcodes b on b.barcodeID=i.barcodeID
		join inv.styles s on s.styleID=b.styleID
		join org.divisions d on d.divisionID=i.divisionID
		where s.orderID= @orderid and i.logstateID= inv.logstate_id('IN-WAREHOUSE')
	group by d.divisionfullname
)

select 
	t.transactiondate, 
	c.contractor vendor, 
	c2.contractor showroom, 
	d.division,
	se.season, 
	cr.currencycode currency, 
	cl.orderclassRus, 
	o.markup, 
	o.orderID, qty, amount, 
	p.lfmname
from inv.orders o 
	join inv.transactions t on t.transactionID=o.orderID
	left join org.contractors c on c.contractorID=o.vendorID
	left join org.contractors c2 on c2.contractorID=o.showroomID
	left join inv.seasons se on se.seasonID=o.seasonID
	join cmn.currencies cr on cr.currencyID=o.currencyID
	outer apply _division d	
	join org.persons p on p.personID=t.userID
	join inv.orderclasses cl on cl.orderclassID=o.orderclassID
where o.orderID= @orderid
GO

select * from inv.orderHeader_(82446)

