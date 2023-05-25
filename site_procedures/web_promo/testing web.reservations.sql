select r.* , s.reservation_state
from inv.site_reservations r
	join inv.site_reserve_states s on s.reservation_stateid=r.reservation_stateid;

--select STRING_AGG(cast(reservationid as varchar(max))+'-' + format(expiration, 'yyyy.MM.dd HH:ss'), ',') as str
select STRING_AGG(cast(reservationid as varchar(max)), ',') from inv.site_reservations r
where r.reservation_stateid = inv.reservation_state_id('active')

select t.*,  tt.transactiontype
from inv.transactions t		
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
where 
	t.transactiontypeID in (32, 33, 34) and
	t.transactionID>=77216 order by 1 desc;

--select d.* , e.eventClosed from web.promo_events e join web.promo_styles_discounts d on d.eventid= e.eventid


--exec web.reservations_clear

--exec inv.transaction_delete 77257
--select * 
--from inv.sales s
--	join inv.sales_goods sg on sg.saleID= s.saleID
--where s.saleID>77275
--order by 1 desc
select * from web.active_orders_v

--select  web.promo_discount_f('9167834248', 19628, '56210')
--select * 
--from web.promo_events e
--	join web.promo_styles_discounts d on d.eventid=e.eventid

--select * from web.promo_log where custid= 17448 and used = 'False'
select * from web.promo_events