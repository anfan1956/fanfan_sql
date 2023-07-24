declare @transid int = 78091;
select r.* , s.reservation_state
from inv.site_reservations r
	join inv.site_reserve_states s on s.reservation_stateid=r.reservation_stateid;
select l.*, s.linkState from web.payment_links l join web.payment_link_states s on s.stateid=l.stateid
--select STRING_AGG(cast(reservationid as varchar(max))+'-' + format(expiration, 'yyyy.MM.dd HH:ss'), ',') as str
select STRING_AGG(cast(reservationid as varchar(max)), ',') from inv.site_reservations r
where r.reservation_stateid = inv.reservation_state_id('active')

select t.*,  tt.transactiontype
from inv.transactions t		
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
where 
	t.transactiontypeID in (32, 33, 34) and
	t.transactionID>=78000 order by 1 desc;

--exec web.reservations_clear

select * 
from inv.sales s
	join inv.sales_goods sg on sg.saleID= s.saleID
where s.saleID>@transid  - 8
order by 1 desc
select * from web.active_orders_v
select * from web.promo_log where custid= 17448 and used = 'False'
--exec inv.transaction_delete @transid