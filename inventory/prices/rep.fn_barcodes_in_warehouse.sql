USE [fanfan]
GO
/****** Object:  UserDefinedFunction [rep].[fn_barcodes_in_warehouse]    Script Date: 27.08.2022 10:24:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [rep].[fn_barcodes_in_warehouse]( @divisionfullname varchar(50) )
returns table as return

WITH _s (styleID, discount, num) as(
	SELECT 
		p.styleID,
		p.discount ,
		ROW_NUMBER() OVER (PARTITION BY P.styleID ORDER BY P.pricesetID desc)
	FROM inv.prices p
)

SELECT 
	se.season, 
	br.brand, 
	s.article,
	i.inventorytyperus category, 
	c.color, 
	sz.size,
	b.barcodeID,
	ISNULL(s.cost_adj, 1) * s.cost * r.rate * r.markup price, 
	st.discount
FROM inv.v_r_inwarehouse v
	JOIN org.divisions d ON D.divisionID=v.divisionID 
					AND D.divisionfullname=@divisionfullname
	JOIN inv.barcodes b ON b.barcodeID=v.barcodeID
	JOIN inv.styles s ON s.styleID=b.styleID
	JOIN inv.orders o ON o.orderID= s.orderID
	JOIN inv.seasons se ON se.seasonID=s.seasonID
	JOIN inv.brands br ON br.brandID=s.brandID
	JOIN inv.inventorytypes i ON i.inventorytypeID=s.inventorytypeID
	JOIN inv.colors c ON c.colorID=b.colorID
	JOIN inv.sizes sz ON sz.sizeID=b.sizeID
	JOIN _s st ON s.styleID=st.styleID
	JOIN inv.current_rate_v r ON r.divisionid= d.divisionID
							AND r.currencyid= o.currencyID
WHERE st.num =1

go