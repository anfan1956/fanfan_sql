if OBJECT_ID ('web.photos_colors_') is not null drop function web.photos_colors_
go
create function web.photos_colors_(@parentid int) returns table as
return
with _colors (color ) as (
	select cmn.norm_(c.color)
	from inv.barcodes b
		join inv.styles s on s.styleID=b.styleID
		join inv.inventory i on i.barcodeID=b.barcodeID			
		join inv.colors c on c.colorID=b.colorID
	where s.parent_styleid = @parentid
		and i.logstateID in (8)
		and i.divisionID in (0, 14, 18, 25, 27)
	group by cmn.norm_(c.color) 
	having sum (i.opersign)>0
	)
select photo_filename, upper(cl.color ) color, photo_priority
from inv.styles_photos p
	join inv.barcodes b on b.barcodeID=p.barcodeid
	join inv.colors c on c.colorID= b.colorID
	right join _colors cl on cl.color= cmn.norm_(c.color)
where p.parent_styleid =@parentid	


go

