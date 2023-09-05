
if OBJECT_ID('inv.styleColor_photo_') is not null drop function inv.styleColor_photo_
go
create function inv.styleColor_photo_(@parent_stlyleid int, @color varchar(max)) returns varchar(max) as
begin

	declare @photo varchar(max);
		select  top 1 @photo = p.photo_filename 
		from inv.styles_photos p
			join inv.barcodes b on b.barcodeID = p.barcodeid
			join inv.colors c on c.colorID=b.colorID
		where parent_styleid = @parent_stlyleid 
		and cmn.norm_(c.color)= cmn.norm_(@color)
		order by photo_filename 
	return isnull(@photo, 'None')
end
go

select * from inv.styles_photos
declare @bcnew int = 659594
declare @photo varchar(max)='_M3Q9792_orange.jpg'

declare @color varchar(max) = 
	--'34300 JET BLACK' 
	'57450 ARANCIONE'
, @parent_styleid int = 19703


select * from inv.styles_catalog_v where styleid=@parent_styleid
select inv.styleColor_photo_(@parent_styleid, @color)