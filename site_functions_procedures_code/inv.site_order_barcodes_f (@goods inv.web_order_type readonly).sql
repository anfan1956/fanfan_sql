USE [fanfan]
GO
ALTER function [inv].[site_order_barcodes_f] (@goods inv.web_order_type readonly) returns table as return
	with _s(styleid, size, color, qty, barcodeid, num) as (
	select g.styleid, g.size, g.color, g.qty,  b.barcodeID, ROW_NUMBER() over(partition by b.sort_barcodeid order by b.barcodeid) num
	from @goods g
		join inv.barcodes b on b.styleID=g.styleid
		join inv.sizes sz on sz.sizeID=b.sizeID and g.size=sz.size
		join inv.colors cl on cl.colorID=b.colorID and cl.color=g.color	
	)
	select barcodeid, styleid
	from _s
	where num <=qty;
go

declare @goods inv.web_order_type, @userid int =  17201, @message varchar(max);
insert @goods (styleid, size, color, qty) values 
	(19212, 'XS', 'cappuchino', 1), 
	(19212, 'L', 'PENCIL', 2),
	(19314, 'L', '677 mist wi', 1), 
	(19321, 'M', 'CHARCOAL FUME', 1);

select barcodeid, styleid from inv.site_order_barcodes_f(@goods)

