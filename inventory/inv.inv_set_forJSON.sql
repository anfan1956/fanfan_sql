if OBJECT_ID ('inv.inv_set_forJSON') is not null drop function inv.inv_set_forJSON
go
create function inv.inv_set_forJSON(@styleid int) returns varchar(max) as
begin
	declare @set varchar(max)
	select @set = isnull((select  upper(color) color, size, sum(qty) qty from inv.style_colors_sizes_avail (@styleid) 
    group by upper(color), size, sizeid  order by sizeid for json path), (select 'not available' styleid  for json path))
		
	return @set
end
go

declare @styleid int = 187918
select inv.inv_set_forJSON(@styleid)