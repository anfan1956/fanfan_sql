if OBJECT_ID('inv.barcodesInShops_v') is not null drop view inv.barcodesInShops_v
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
	br.brand,s.article, 
	it.inventorytyperus category, c.color, 
	sz.size, 
	b.barcodeid, 

	round(
	case o.orderclassID
		when 3 then cte.price
		else 
			ISNULL(s.cost_adj, 1) * s.cost * r.rate* r.markup
		end, -1) price,
--	cte.price,
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
	join _s cte on cte.styleID=s.styleID and cte.num=1
	left JOIN inv.current_rate_v r ON r.divisionid= d.divisionID AND r.currencyid= o.currencyID
	left join cmn.currencies cr on cr.currencyID=s.currencyID

where 
	--o.orderID is not null 	and 
	b.divisionid in (18, 25, 27)

go 

select 
	orderid, season, brand, article, category, color, size, barcodeid, price, discount
from inv.barcodesInShops_v
where shop = '05 Уикенд' and orderid =81079


select * 
from inv.orders o 
	join inv.seasons s on s.seasonID=o.seasonID
where o.orderID= 81079
