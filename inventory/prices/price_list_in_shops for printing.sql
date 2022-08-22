USE fanfan
GO

IF OBJECT_ID('rep.fn_barcodes_in_warehouse') IS NOT NULL DROP FUNCTION rep.fn_barcodes_in_warehouse
GO
create function rep.fn_barcodes_in_warehouse( @divisionfullname varchar(50) )
returns table as return

	select g.season, g.brand, g.article, g.category, g.color, g.size, g.barcodeID, g.baseprice as price, g.discount
	from inv.v_goods g
		join inv.v_r_inwarehouse r on r.barcodeID = g.barcodeID 
		join org.divisions d on d.divisionID = r.divisionID and d.divisionfullname = @divisionfullname
GO

--I want to add rates in shops
