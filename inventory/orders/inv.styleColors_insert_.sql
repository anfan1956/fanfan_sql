if OBJECT_ID('inv.styleColors_insert_') is not null drop proc inv.styleColors_insert_
go
create proc inv.styleColors_insert_ @color varchar(max), @styleid int as 
begin
	;with  s(color, orderid) as (
		select @color, s.orderID
		from inv.styles s		
		where s.styleID = @styleid
	)
	merge inv.colors as t using s
	on t.color=s.color and t.orderid= s.orderid
	when not matched then 
		insert (color, orderid)
		values (color, orderid);
	select @@ROWCOUNT
end 
go

declare @color varchar(max) = 'Black', @styleid int = 20407
--set nocount on; exec inv.styleColors_insert_ @color, @styleid
--delete inv.colors where colorID= 15662

