set statistics time on
declare @styleid int =19166
--select inv.brandby_id(@styleid)
select photo_filename from inv.styles_catalog_v c
where c.styleid=@styleid
select inv.photoby_id (@styleid)

set statistics time off