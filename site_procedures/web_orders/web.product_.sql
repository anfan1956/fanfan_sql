﻿declare @parentid int
select @parentid = 13530 -- 19996;
if OBJECT_ID('web.product_') is not null drop function web.product_
go
create function web.product_ (@parentid int) returns varchar(max) as 
begin
	declare @product varchar(max);

	with s (barcodeid, sizeid, colorid, parentid) as (
	select distinct barcodeid, sizeid, colorid, parent_styleid
	from inv.styles s	
		join inv.barcodes b on b.styleID = s.styleID
		where s.parent_styleid = @parentid
	)

, product (photo, parentid, brand, inventorytyperus, article, composition, color, price, discount, promo) as (
		select distinct 
			v.photo_filename, 
			s.parent_styleid, 
			b.brand, 
			it.inventorytyperus, 
			v.article, 
			v.composition,
			pc.color,
			cast (round(v.price, 0) as int), 
			v.discount, 
			isnull(d.discount, 0)			
		from inv.styles s
			join inv.brands b on b.brandID= s.brandID
			join inv.inventorytypes it on it.inventorytypeID= s.inventorytypeID
			join inv.styles_catalog_v v on v.styleid=s.parent_styleid
			left join  web.promo_styles_discounts d on d.styleid=s.parent_styleid
			left join web.promo_events e on e.eventid=d.eventid and	e.eventClosed=0 
					and cast(datefinish as date ) >= cast(getdate() as date)
			cross apply web.photos_colors_(@parentid) pc
		where s.parent_styleid = @parentid and pc.photo_filename= v.photo_filename

	)
, sizes (sizeid, size) as (
		select distinct s.sizeid, size 
		from s 
			join inv.sizes sz on sz.sizeID=s.sizeID
	)
, colors (color, sizeID, qty)  as (
	select distinct cmn.norm_(color) color, s.sizeID, sum(opersign)
	from s 
		join inv.colors c on c.colorID=s.colorID
		join inv.inventory i on i.barcodeID=s.barcodeID
	where i.logstateID = 8 and divisionID in (0, 14, 18, 25, 27)
	group by cmn.norm_(color), s.sizeID
	having sum(i.opersign)>0
	)
, colors_only (color) as (
	select distinct upper(cmn.norm_(color)) from colors 
	)
, t (photo) as (select photo_filename from web.photos_colors_(@parentid) )
, items (color,  qtys) as (
	select c.color, 
	(
		select s.size, isnull(col.qty, 0) qty 
		from sizes s
			cross apply colors_only co
			left join colors col on col.sizeid=s.sizeID and col.color=c.color
			where col.color=c.color
		group by s.size, isnull(col.qty, 0) 
		for json path
		) 
	from sizes s
		cross apply colors_only c
		left join colors cl on cl.sizeid=s.sizeID and cl.color=c.color
	group by c.color
)
select @product = (
	select 
		p.photo, 
		p.parentid styleid, p.brand,  p.inventorytyperus category, 
		p.article article, 
		UPPER(p.color) color, 
		p.composition, p.price, p.discount, p.promo,
		(select  STRING_AGG( size, ',') WITHIN GROUP ( ORDER BY sizeid  ) sizes from 	sizes ) sizes ,
		(select distinct STRING_AGG( UPPER(color), ',')  colors from 	colors_only ) colors,
		(select STRING_AGG( t.photo, ',') photo from t) photos, 
		(select photo_filename img, color from web.photos_colors_(@parentid) for json path ) images, 
		(select * from items for json path) items
	from product p
	for json path
)
return @product
end
go


declare @start datetime = getdate()
declare @parentid int
select @parentid = 19996;
select web.product_(@parentid)
declare @end datetime = getdate()
select DATEDIFF(MS, @start, @end)

