if OBJECT_ID('inv.styleOrderColors_') is not null drop function inv.styleOrderColors_
go
create function inv.styleOrderColors_ (@styleid int) returns table as return
	select distinct color
	from 
		inv.styles s 
		join inv.colors c on c.orderID=s.orderID
	where s.styleID = @styleid

go
declare @styleid int = 20407;

select color from inv.styleOrderColors_(@styleid)
select * from inv.colors order by 1 desc
go

