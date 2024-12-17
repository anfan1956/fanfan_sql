if OBJECT_ID('inv.styleColors_') is not null drop function inv.styleColors_
go
create function inv.styleColors_(@brandid int) returns table as return
with s as (
select trim (upper(color)) color
from inv.styles s
	join inv.barcodes b on b.styleID = s.styleID and s.brandID = @brandid
	join inv.colors c on c.colorID=b.colorID
)
select distinct trim( cmn.RemoveDigits( color)) color
from s;
go

declare @brandid int = 343
select color from inv.styleColors_(@brandid)
