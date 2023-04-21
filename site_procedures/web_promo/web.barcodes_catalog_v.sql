if OBJECT_ID('web.barcodes_catalog_v') is not null drop view web.barcodes_catalog_v
go
create view web.barcodes_catalog_v as

with _barcodes(barcodeid, styleid, qty, divisionid) as (
	select 
		i.barcodeID, b.styleID, sum(i.opersign), i.divisionID
	from inv.inventory i
		join inv.barcodes b on b.barcodeID=i.barcodeID
	where i.logstateID = 8
	group by i.barcodeID, b.styleID, i.divisionID
	having sum(i.opersign)>0
)
, _arts_cat(article, price, discount) as (
	select article, price, discount
	from inv.styles_catalog_v c
)
, _art_ph(article, styleid, parent_styleid) as (
	select distinct  s.article, s.styleid, p.parent_styleid
	from inv.styles_photos p
		join inv.styles s on s.styleID=p.styleid
--	where p.parent_styleid= @parentid
)
, f (brand, article, styleid, parentid, 
		size, sizeid, category, barcodeID, color, division, price, discount) as (
	select 
		br.brand, a.article, s.styleID, p.parent_styleid,
		sz.size, b.sizeid, it.inventorytyperus, 
		b.barcodeID, c.color, d.divisionfullname, 
		price, discount
	from _arts_cat a
		join _art_ph p on p.article=a.article
		join inv.styles s on s.styleID=p.styleid
		join _barcodes q on q.styleid=s.styleID
		join inv.barcodes b on b.barcodeID=q.barcodeid
		join inv.sizes sz on sz.sizeid=b.sizeID
		join inv.brands br on br.brandID=s.brandID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		join inv.colors c on c.colorID=b.colorID
		join org.divisions d on d.divisionID=q.divisionid
where q.qty>0
)
select 
	brand, parentid, 
	category, 
	article, 
	styleID, 
	size, sizeid, 
	color, barcodeID, division, price, discount
from f 
go

declare @parentid int = 19629;
declare @time1 datetime=getdate();

--select 	brand,	parentid, category,	article	,styleID, size,color, barcodeID
--select distinct parentid 
select  distinct article, category, price, discount from web.barcodes_catalog_v c where c.parentid = 19624 

--where parentid = @parentid
--order by brand, parentid, styleid, sizeid 



declare @time2 datetime=getdate();
select DATEDIFF(MS,@time1, @time2);

--with _barcodes (barcodeid, divisionid) as (
--	select i.barcodeID, i.divisionID
--	from inv.inventory i 
--	where i.logstateID=inv.logstate_id('in-warehouse')
--	group by i.barcodeid, i.divisionID
--	having sum (i.opersign)>0
--)
--select * 
--from web.barcodes_catalog_v c
--	join _barcodes b