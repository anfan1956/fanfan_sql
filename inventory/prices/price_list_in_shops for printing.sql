USE fanfan
GO

IF OBJECT_ID('rep.fn_barcodes_in_warehouse') IS NOT NULL DROP FUNCTION rep.fn_barcodes_in_warehouse
GO
create function rep.fn_barcodes_in_warehouse( @divisionfullname varchar(50) )
returns table as return

WITH _prices (styleID, discount, num)  as (
	SELECT P.styleID, p.discount, ROW_NUMBER() OVER(PARTITION BY p.styleID ORDER BY p.pricesetID desc)
	FROM inv.prices p 
		JOIN inv.pricesets p1 on p1.pricesetID= P.pricesetID
)
, _current_prices (styleID, discount) AS (
	SELECT p.styleID, p.discount FROM _prices p 
	WHERE p.num=1
	)
SELECT 
	s1.season, 
	br.brand, 
	s.article, 
	i.inventorytyperus category, 
	cl.color,
	sz.size, 
	v.barcodeID, 
	isnull(s.cost_adj, s.cost) * r.rate * r.markup price,
	c.discount 

FROM inv.v_r_inwarehouse v
	JOIN org.divisions d ON D.divisionID=v.divisionID
	JOIN inv.barcodes b ON b.barcodeID=v.barcodeID
	JOIN inv.styles s ON s.styleID=b.styleID
	JOIN inv.orders o ON o.orderID=s.orderID
	JOIN _current_prices c ON c.styleID=s.styleID
	JOIN inv.current_rate_v r ON r.divisionid= d.divisionID
							AND r.currencyid= o.currencyID
	JOIN inv.seasons s1 ON s1.seasonID=o.seasonID
	JOIN inv.brands br ON br.brandID=s.brandID
	JOIN inv.inventorytypes i ON i.inventorytypeID=s.inventorytypeID
	JOIN inv.colors cl ON cl.colorID=b.colorID
	JOIN inv.sizes sz ON sz.sizeID=b.sizeID
WHERE D.divisionfullname = @divisionfullname

GO

--this VERSION adjusts to the shop markup and prices

