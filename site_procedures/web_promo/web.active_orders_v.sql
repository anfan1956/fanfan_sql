﻿
if object_id('web.active_orders_v') is not null drop view web.active_orders_v
go
create view web.active_orders_v as
	select 	
		cust.prime_phone_f(r.custid) телефон, 
		r.custid id_клиента, 
		r.reservationid id_заказа, 
		format(expiration, 'dd MMMM HH:mm') действителен_до,
		bi.styleID, 
		s.barcodeid barcode, 
		bi.артикул, 
		bi.бренд, 
		bi.категория, 
		bi.размер, 
		bi.цвет,
		s.amount 

	from inv.site_reservations r 
		join inv.site_reservation_set s on s.reservationid=r.reservationid
		cross apply inv.barcodeid_info_f (s.barcodeid) bi
	where r.reservation_stateid=inv.reservation_state_id('active')
go	

declare @phone char(10) = '9167834248'
select * from web.active_orders_v o where  o.телефон= @phone
select * from inv.site_reservations
