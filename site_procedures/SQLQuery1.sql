declare @barcodes table (barcodeid int);
declare @goods inv.web_order_type, @userid int =  17201, @message varchar(max);
insert @goods (styleid, size, color, qty) values 
	(19212, 'XS', 'cappuchino', 1), 
	(19212, 'L', 'PENCIL', 2),
	(19314, 'L', '677 mist wi', 1), 
	(19321, 'M', 'CHARCOAL FUME', 1);
insert @barcodes
select barcodeid from inv.site_order_barcodes_f(@goods)

select b.barcodeID, b.styleid, size, article, s.brandID, br.brand, s.cost
from inv.barcodes b
	join @barcodes bc on bc.barcodeid= b.barcodeID
	join inv.sizes sz on sz.sizeID=b.sizeID
	join inv.styles s on s.styleID= b.styleID
	join inv.brands br on br.brandID=s.brandID

