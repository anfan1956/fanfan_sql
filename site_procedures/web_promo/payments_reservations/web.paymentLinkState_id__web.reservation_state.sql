declare @transid int = 78091;

select r.* , s.reservation_state
from inv.site_reservations r
	join inv.site_reserve_states s on s.reservation_stateid=r.reservation_stateid;
select l.*, s.linkState from web.payment_links l join web.payment_link_states s on s.stateid=l.stateid



if OBJECT_ID ('web.paymentLinkState_id') is not null drop function web.paymentLinkState_id
go 
create function web.paymentLinkState_id (@state varchar(max)) returns int as
begin
	declare @stateid int;
	select @stateid = stateid from web.payment_link_states p where p.linkState= @state
	return @stateid
end
go

if OBJECT_ID('web.reservation_state') is not null drop proc web.reservation_state
go
create proc web.reservation_state @orderid int  as
begin
set nocount on;
	declare @state varchar(max);
		select @state = reservation_state
		from inv.site_reservations r
			join inv.site_reserve_states s on s.reservation_stateid=r.reservation_stateid 
		where r.reservationid=@orderid;
		if (@state <> 'active')
			update l set l.stateid= web.paymentLinkState_id(@state)
			from web.payment_links l where l.orderid = @orderid

		select @state; 
	;
	
end
go



