﻿declare @phone char(10) = '9167834248', @orderid  int  =79404
declare @barcodeid int = 648747;
select *
from inv.webOrders_toShip_v w where w.[телефон клиента]=@phone

if OBJECT_ID('inv.barcode_props_') is not null drop function inv.barcode_props_
go
create function inv.barcode_props_(@barcodeid int) returns table as return
	select 
		b.barcodeID, 
		br.brand, 
		it.inventorytyperus category, 
		s.styleID,
		o.orderID, 
		oc.orderclass orderType, 
		se.season,
		s.article, 
		cmn.norm_(c.color) color,
		sz.size,
		s.cost, 
		o.currencyID, 
		cn.contractor showroom
	from inv.barcodes b
		join inv.styles s on s.styleID=b.styleID
		join inv.brands br on br.brandid=s.brandID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		join inv.colors c on c.colorID = b.colorID
		join inv.sizes sz on sz.sizeID=b.sizeID
		join inv.orders o on o.orderID=s.orderID
		join inv.orderclasses oc on oc.orderclassID=o.orderclassID
		join org.contractors cn on cn.contractorID = o.showroomID
		left join inv.seasons se on se.seasonID = o.seasonID
	where b.barcodeID =@barcodeid
go
declare @barcodeid int = 668342;
select * from inv.barcode_props_(@barcodeid)

