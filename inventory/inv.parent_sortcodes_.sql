if OBJECT_ID('inv.parent_sortcodes_') is not null drop function inv.parent_sortcodes_
go
create function inv.parent_sortcodes_ (@parentid int, @color varchar(max), @size varchar(max)) returns table as return
	with s as (
	select 
		s.parent_styleid, s.styleid, b.sort_barcodeID, 
		c.color, sz.size, b.barcodeid, i.divisionID,
		sum (i.opersign) qty
	from inv.styles s 
		join inv.barcodes b on b.styleid = s.styleID
		join inv.colors c on c.colorID= b.colorID
		join inv.sizes sz on sz.sizeID=b.sizeID
		join inv.sizegrids sg on sg.sizegridID=s.sizegridID and sz.sizegridID=sg.sizegridID
		join inv.inventory i on i.barcodeID =b.barcodeID
	where 
		s.parent_styleid = @parentid
		and c.color= @color
		and sz.size=@size
		and i.logstateID = inv.logstate_id('in-warehouse')
	group by s.parent_styleid, s.styleID, b.sort_barcodeID, c.color, sz.size, b.barcodeid, i.divisionID
	having sum(i.opersign)>0
	)
	select * from s
go


if OBJECT_ID('inv.parent_sortcodes_JSON') is not null drop function inv.parent_sortcodes_JSON
go 
create function inv.parent_sortcodes_JSON
	(
		@js_string as varchar(max)
	) 
	returns @out table 
	(
		parentid int, 
		styleid int, 
		sort_barcodeid int, 
		color varchar(max), 
		size varchar(10), 
		barcodeid int, divisionid int, 
		qty int
	)
	as

begin

	declare @styleid int, @color varchar(max), @size varchar(max);

	select @styleid = styleid, @color = color, @size = size
	from OPENJSON (@js_string)
	with (
			color VARCHAR(50) '$.color', 
			size varchar(50) '$.size', 
			styleid VARCHAR(50) '$.styleid'
			) as jsonValues;
	insert @out 
	select parent_styleid, styleid, sort_barcodeID, color, size, barcodeid, divisionID, qty 
	from  inv.parent_sortcodes_(@styleid, @color, @size)
	return
end
go

declare @color varchar(max) = 'WHITE'
declare @size varchar(max) = '3'
declare @parentid int = 13530

select * from inv.parent_sortcodes_(@parentid, @color, @size)
select count(qty) from inv.parent_sortcodes_(@parentid, @color, @size)

declare @myStr varchar(max)
set @myStr = 
'{"size": "3", "color": "WHITE", "phone": "9167834248", "styleid": "13530"}';
--'{"color":"WHITE","size":"4","styleid":"13530","price":"19125","discount":"0.0","phone":"9167834248","qty":"1","promoDiscount":"0.0","uuid":"6a048147-3384-4a23-8185-7702c610860d"}'


select COUNT(barcodeid) from inv.parent_sortcodes_JSON(@myStr)


