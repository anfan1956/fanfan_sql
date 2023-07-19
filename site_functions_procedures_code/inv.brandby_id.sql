if OBJECT_ID('inv.brandby_id') is not null drop function inv.brandby_id
go

create function inv.brandby_id(@styleid int) returns varchar(max) as 
begin
declare @brand varchar (max)
select @brand = b.brand
from inv.styles s
join inv.brands b on b.brandID=s.brandID
where s.styleID = @styleid
return @brand
end

go
if OBJECT_ID('inv.photoby_id') is not null drop function inv.photoby_id
go

create function inv.photoby_id(@styleid int) returns varchar(max) as 
begin
	declare @photo varchar (max)
	select top 1 @photo = s.photo_filename from inv.styles_photos s
	where parent_styleid =@styleid
	return @photo
end

go

select inv.photoby_id (19166)