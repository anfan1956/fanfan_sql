
if object_id('web.active_orders_v') is not null drop view web.active_orders_v
go
create view web.active_orders_v as
	select 	
		cust.prime_phone_f(r.custid) телефон, 
		r.custid id_клиента, 
		r.reservationid id_заказа, 
		da.address_string,
		rp.fio,
		format(expiration, 'dd MMMM HH:mm') действителен_до,
		bi.styleID, 
		s.barcodeid barcode, 
		bi.артикул, 
		bi.бренд, 
		d.divisionfullname склад,
		bi.категория, 
		bi.размер, 
		bi.цвет,
		s.amount 

	from inv.site_reservations r 
		join inv.site_reservation_set s on s.reservationid=r.reservationid
		cross apply inv.barcodeid_info_f (s.barcodeid) bi
		cross apply inv.barcodePrevious_locatiion(s.barcodeid) pl
		join org.divisions d on d.divisionID=pl.divisionID
		join web.delivery_logs dl on dl.orderid= r.reservationid
		left join web.customer_spots cs on cs.spotid=dl.spotid
		left join web.deliveryAddresses da on da.addressid= cs.addressid
		left join web.receiver_phones rp on rp.phoneid=cs.receiver_phoneid
	where r.reservation_stateid=inv.reservation_state_id('active')
	
go	

declare @phone char(10) = '9167834248'
select * from web.active_orders_v o 
--where  o.телефон= @phone
select * from inv.site_reservations
--declare @barcodeid int = 658765
--select * from inv.barcodeid_info_f(658777)
--select * from  inv.barcodePrevious_locatiion(@barcodeid) pl
select s.* 
from inv.site_reservations r
	join inv.site_reservation_set s on s.reservationid=r.reservationid
	cross apply inv.barcodeid_info_f(s.barcodeid) bi
	cross apply inv.barcodePrevious_locatiion(s.barcodeid) pl
	join org.divisions d on d.divisionID=pl.divisionID
	join web.delivery_logs dl on dl.orderid= r.reservationid
	left join web.customer_spots cs on cs.spotid=dl.spotid
	left join web.deliveryAddresses da on da.addressid= cs.addressid
	left join web.receiver_phones rp on rp.phoneid=cs.receiver_phoneid
	where r.reservation_stateid = 1

