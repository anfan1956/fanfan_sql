declare @p table (pid  int)
insert @p values (19166), (20129)

if OBJECT_ID('web.parentStyles_photos') is not null drop function web.parentStyles_photos
go
create function web.parentStyles_photos() returns varchar(max) as 
begin 
declare @styles varchar(max);

select @styles =(select  photo_filename photo, parent_styleid 
from inv.styles_photos s

for json path)
return @styles
end 
go

select web.parentStyles_photos()