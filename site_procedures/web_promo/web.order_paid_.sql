
if OBJECT_ID('web.order_paid_') is not null drop function web.order_paid_
go
create function web.order_paid_(@orderid int) returns varchar(max) as 
begin
	declare @paid varchar(max)

		select @paid =  s.reservation_state
		from inv.site_reservations r
			join inv.site_reserve_states s on s.reservation_stateid=r.reservation_stateid
		where r.reservationid=@orderid

	return @paid
end
go

declare @orderid int = 78111

select s.reservation_state
from inv.site_reservations r
	join inv.site_reserve_states s on s.reservation_stateid=r.reservation_stateid
where r.reservationid=@orderid
	