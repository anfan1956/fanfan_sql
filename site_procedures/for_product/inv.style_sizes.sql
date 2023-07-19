
if OBJECT_ID('inv.style_sizes_str') is not null drop function inv.style_sizes_str
if OBJECT_ID('inv.style_sizes') is not null drop function inv.style_sizes
go
create function inv.style_sizes (@styleid int)  returns table as
return
with s as (
SELECT distinct sz.size, sz.sizeID 
from inv.styles s
	join inv.sizegrids sg on sg.sizegridID=s.sizegridID
	--join inv.sizes sz on sz.sizegridID=sg.sizegridID
	join inv.inventory i on i.transactionID=s.orderID and i.opersign=1
	join inv.barcodes b on b.barcodeID=i.barcodeID
	join inv.sizes sz on sz.sizeID=b.sizeID and sz.sizegridID=sg.sizegridid
where s.styleID =@styleid
)
select * from s;
go
create function inv.style_sizes_str (@styleid int)  returns varchar(max) as
begin

DECLARE @sizes VARCHAR(max) 
SELECT @sizes = COALESCE(@sizes + ', ', '') + '"' + sz.size + '"'
from inv.styles s
	join inv.sizegrids sg on sg.sizegridID=s.sizegridID
	join inv.sizes sz on sz.sizegridID=sg.sizegridID
where s.styleID =@styleid
order by sz.sizeID
return @sizes
end
go
declare @styleid int =20324
select inv.style_sizes_str(@styleid)

select size from inv.style_sizes(@styleid)