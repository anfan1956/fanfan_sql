
if OBJECT_ID('web.order_paid_') is not null drop function web.order_paid_
go
create function web.order_paid_(@orderid int) returns bit as 
begin
	declare @paid bit
	select @paid = isnull((
		select orderid 
		from inv.webOrders_toShip_v 
		where orderid = @orderid), 0)
	return @paid
end
go

declare @orderid int = 77699;
select web.order_paid_(@orderid)