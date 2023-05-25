use fanfan
go


if OBJECT_ID('web.promo_styles_active_') is not null drop view web.promo_styles_active_
go
create view web.promo_styles_active_ as
with _photos (eventid, styleid, photo, discount,  num) as(
	select 
		d.eventid, d.styleid, p.photo_filename, d.discount,
		ROW_NUMBER() over(partition by p.styleid order by p.photo_filename)
	from web.promo_events e
	join web.promo_styles_discounts d on d.eventid=e.eventid
	join inv.styles_photos p on p.parent_styleid=d.styleid
where eventClosed='false'
	and cast(getdate() as date ) between e.datestart and e.datefinish
)
select
	STRING_AGG( cast(eventid as varchar(max)) +'/' + cast(p.styleid as varchar(max)) +'/'+ photo 
		+ ':' + b.brand 
		+ ':' + format(p.discount*100, '#,##0')
		+ ':' + cast(v.price as varchar(max))
		, ',') as styles_string
from _photos p 
	join inv.styles s on s.styleID=p.styleid
	join inv.brands b on b.brandID=s.brandID
	join web.stylesPrices_discounts_v v on v.styleID=p.styleid
where p.num =1
go



select styles_string from web.promo_styles_active_;

with _photos (eventid, styleid, photo,  num) as(
	select d.eventid, d.styleid, p.photo_filename, ROW_NUMBER() over(partition by p.styleid order by p.photo_filename)
	from web.promo_events e
	join web.promo_styles_discounts d on d.eventid=e.eventid
	join inv.styles_photos p on p.styleid=d.styleid
where eventClosed='false'
	and cast(getdate() as date ) between e.datestart and e.datefinish
)
select 
	STRING_AGG( cast(eventid as varchar(max)) +'/' + cast(p.styleid as varchar(max)) +'/'+ photo + ':' + b.brand , ',') as styles_string
from _photos p
	join inv.styles s on s.styleID=p.styleid
	join inv.brands b on b.brandID=s.brandID
where p.num =1
go
 
select cc.composition
from inv.styles s 
	join inv.compositions c on c.compositionID=s.compositionID
	join inv.v_compositions cc on cc.compositionID=c.compositionID
where s.styleID=19166

