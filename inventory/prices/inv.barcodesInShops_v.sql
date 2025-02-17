﻿if OBJECT_ID('inv.barcodesInShops_v') is not null drop view inv.barcodesInShops_v
go

create view inv.barcodesInShops_v as

WITH _s (styleID, discount, price, num) as(
	SELECT 
		p.styleID,
		p.discount, 
		p.price,
		ROW_NUMBER() OVER (PARTITION BY P.styleID ORDER BY P.pricesetID desc)
	FROM inv.prices p
)
, _barcodes ( barcodeid, colorid, sizeid, styleid, divisionid) as (
select  i.barcodeID, b.colorID, b.sizeID, b.styleID, i.divisionID
from inv.inventory i 
	join inv.barcodes b on b.barcodeID=i.barcodeID
where i.logstateID = inv.logstate_id('in-warehouse')
group by i.barcodeID, i.divisionID, b.styleID, b.colorID, b.sizeID
having sum(i.opersign)>0
)
select 
	isnull(s.orderID, o.orderID) orderid,
	se.season, 
	br.brand,
	s.styleID,
	s.article, 
	it.inventorytyperus category, 
	c.color, 
	sz.size, 
	b.barcodeid, 
	round (cte.price, -1) price,
	s.retail,
	isnull(cte.discount, 0) discount, 
	d.divisionfullname shop
from _barcodes b
	join inv.styles s on s.styleID=b.styleid
	join inv.orders o on o.orderID=s.orderID
	join inv.seasons se on se.seasonid=isnull(o.seasonID, 0)
	join inv.brands br on br.brandID=s.brandID
	join org.divisions d on d.divisionID=b.divisionid
	join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
	join inv.colors c on c.colorID=b.colorid
	join inv.sizes sz on sz.sizeID=b.sizeid
	--left join inv.orders o on o.orderID=s.orderID
	left join _s cte on cte.styleID=s.styleID and cte.num=1
	left JOIN inv.current_rate_v r ON r.divisionid= d.divisionID AND r.currencyid= o.currencyID
	left join cmn.currencies cr on cr.currencyID=s.currencyID

where 1=1
	--o.orderID is not null 	and 
	and d.datefinish is null 
	and d.retail = 'True'

go 

select 
	orderid, season, brand, styleID, article, category, color, size, barcodeid, price, discount
from inv.barcodesInShops_v
where shop = '07 Уикенд' 


