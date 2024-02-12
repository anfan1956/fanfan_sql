declare @orderid int = 81048

if OBJECT_ID('inv.orderFullView_') is not null drop function inv.orderFullView_
go
create function inv.orderFullView_(@orderid int) returns table as return
select 
	s.orderID, 
	d.divisionfullname,
	s.styleID, 
	br.brand, 
	se.season, 
	s.article, 
	it.inventorytyperus product, 
	cr.currencycode, 
	s.cost, 
	s.retail,
	sum(opersign) quantity
from inv.barcodes b
	join inv.styles s on s.styleID=b.styleID
	join inv.inventory i on i.barcodeID=b.barcodeID
	join inv.seasons se on se.seasonID=s.seasonID
	join inv.brands br on br.brandID=s.brandID
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join cmn.currencies cr on cr.currencyID=s.currencyID
	join org.divisions d on d.divisionID=i.divisionID
where s.orderID = @orderid
	and i.opersign = 1
group by 
	s.orderID, 
	d.divisionfullname,
	s.styleID, 
	br.brand, 
	se.season, 
	s.article, 
	it.inventorytyperus, 
	cr.currencycode, 
	s.cost, 
	s.retail

go
select * from inv.order_styles_(81048)	



