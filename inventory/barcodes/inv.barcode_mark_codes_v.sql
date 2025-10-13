create or alter view inv.barcode_mark_codes_v 
	as 
		select
			b.barcodeID							as barcode
			, o.orderID
			, s.article
			, it.inventorytyperus				as category
			, c.color
			, sz.size
			, s.cost
			, b.mark_code						as QRcode
		from inv.orders o 
			join inv.styles s on s.orderID = o.orderID
			join inv.barcodes b on b.styleID = s.styleID
			join inv.brands br on br.brandID=s.brandID
			join inv.colors c on c.colorID=b.colorID
			join inv.sizes sz on sz.sizeID=b.sizeID
			join inv.inventorytypes it on it.inventorytypeID= s.inventorytypeID
;
go

declare @orderid int  = 91782
select * from inv.barcode_mark_codes_v b
where b.orderID  = @orderid