
if OBJECT_ID('web.styles_photos_') is not null drop function web.styles_photos_
go
create function web.styles_photos_ (@eventid int) returns table as 
	return

	with _s (styleid, photo, num) as (
	select 
		s.styleid, p.photo_filename, 
		ROW_NUMBER() over (partition by s.styleid order by p.photo_filename) num
	from web.promo_events e
			join web.promo_styles_discounts s on s.eventid=e.eventid
			join inv.styles_photos p on p.styleid=s.styleid		
	where e.eventid=@eventid
	)
	select STRING_AGG(
		cast (styleid as varchar(10)) + '\' + photo, ',') as styles_photos
	from _s s
	where s.num=1
go

declare @eventid int = 1;
select styles_photos from web.styles_photos_(@eventid)

select * from web.promo_events e
join web.promo_styles_discounts d on d.eventid=e.eventid
