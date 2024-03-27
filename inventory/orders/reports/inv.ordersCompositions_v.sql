if OBJECT_ID('inv.ordersCompositions_v') is not null drop view inv.ordersCompositions_v
go
create view inv.ordersCompositions_v as
select 
	o.orderid, 
	v.contractor vendor, 
	cn.contractor showroom,
	s.styleid,
	br.brand,
	s.article, 
	cost, 
	retail, 
	inventorytyperus category, sizegrid,
	color, sz.sizeID, sz.size, 
	sz.sizegridID gridId,
	b.barcodeID
from inv.orders o 
	join inv.styles s on s.orderID= o.orderID
	join inv.barcodes b on b.styleid = s.styleID
	join inv.colors c on c.colorID=b.colorID
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join inv.sizegrids sg on sg.sizegridid=s.sizegridID
	join inv.sizes sz on sz.sizeID=b.sizeID
	join org.contractors v on v.contractorID=o.vendorID
	left join org.contractors cn on cn.contractorID=o.showroomID
	join inv.brands br on br.brandID=s.brandID
--where s.orderID=@orderid
go

declare @orderid int = 81243
select * from inv.ordersCompositions_v
where orderID =@orderid
order by 1 desc
select * from inv.orders where orderID=@orderid