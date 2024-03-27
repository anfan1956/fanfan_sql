if OBJECT_ID('web.topBrands_') is not null drop function web.topBrands_
go
create function web.topBrands_ (@gender varchar(max)) returns table as return 
with sp as	(
	select 
		s.parent_styleid, s.photo_filename photo, isnull(s.photo_priority, 0) priorite,
		ROW_NUMBER( ) over (partition by s.parent_styleid order by isnull(s.photo_priority, 0) desc, s.photo_filename) num
	from inv.styles_photos s 
	)

, s as (
	select  
		s.parent_styleid, 
		st.brandID, 
		sum(i.opersign) qty		
	from sp s
		join inv.styles st on st.parent_styleid= s.parent_styleid
		join inv.barcodes b on b.styleID = st.styleID
		join inv.inventory i on i.barcodeID = b.barcodeID 
	where i.logstateID = inv.logstate_id('sold') and st.gender = 
		case @gender when 'female' then 'f' when 'male' then 'm' end 
		and s.num =1
	group by s.parent_styleid, st.brandID
)

, f as (
	select s.*, sp.photo_filename, ROW_NUMBER() over (partition by brandid order by qty desc
	, photo_filename ) num 
	from s 
		join inv.styles_photos sp on s.parent_styleid=sp.parent_styleid
)
select 	
	photo_filename photo, 
	b.brand, f.parent_styleid styleid, qty
from f
	join inv.brands b on b.brandID=f.brandID
where num =1
go


select photo, brand, styleid, qty from web.topBrands_('female')


--SELECT photo, brand, gender 
--    FROM web.topBrands_('male') 


