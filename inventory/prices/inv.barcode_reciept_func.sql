ALTER function [inv].[barcode_reciept_func] (@barcodeid int) returns table as return
	select 
			g.barcodeID,
			g.brand марка, g.season сезон, g.article артикул, 
			g.category категория, g.size размер, g.color цвет, 
			g.composition, g.baseprice цена, g.discount скидка, 
			g.price, 
			case l.logstate
				when 'IN-WAREHOUSE' then 'В НАЛИЧИИ'
				when 'SOLD'  then 'ПРОДАННЫЙ'
				when 'LOST' then 'УТРАЧЕННЫЙ'
				else l.logstate
			end статус, 
			d.divisionfullname магазин
	from inv.v_goods g 
		join inv.v_remains r on r.barcodeID=g.barcodeID
		join inv.logstates l on l.logstateID=r.logstateID
		join org.divisions d on d.divisionID=r.divisionID		
	where g.barcodeID=@barcodeid
go
declare @shop varchar (25)= '07 ФАНФАН', @barcodeid int =530938
;
