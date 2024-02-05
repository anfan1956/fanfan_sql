if OBJECT_ID('inv.order_styles_') is not null drop function inv.order_styles_
go
create function inv.order_styles_ (@orderid int ) returns table as return

with _totals (styleid, qty, total) as (
	select b.styleID,  sum (i.opersign), sum(s.cost)
	from inv.inventory i
		join inv.barcodes b on b.barcodeID=i.barcodeID
		join inv.styles s on s.styleID=b.styleID
	where i.transactionID =@orderid  and i.opersign=1
	group by b.styleID
)
select  
	b.brand, 
	case s.gender
		when 'm ' then 'муж' when 'f' then 'жен' end gender, 
	it.inventorytyperus, s.article, s.cost, s.retail, sz.sizegrid, 
	s.description, 
	inv.style_composition_(s.styleID) composition, 
	cn.countryrus, 
	s.styleID, 
	isnull(t.qty, 0) qty,
	isnull(t.total, 0) total

from inv.styles s
	join inv.brands b on b.brandid= s.brandID	
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join inv.sizegrids sz on sz.sizegridID=s.sizegridID
	left join _totals t on t.styleid=s.styleID
	left join org.workshops w on w.workshopID=s.workshopID
	left join cmn.countries cn on cn.countryID=w.countryID
	


where s.orderID = @orderid

go

declare @orderid int = 80041 ;select * from inv.order_styles_(@orderid)



