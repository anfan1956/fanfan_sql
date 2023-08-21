if OBJECT_ID('web.basket_action_fromJSON_') is not null drop function web.basket_action_fromJSON_
go 
create function web.basket_action_fromJSON_(@json varchar(max))
	returns table 
as return

with s ( styleid, color, size, qty, phone, the_session, the_action) as (
select  styleid, color, size, qty, phone, the_session, the_action
from OPENJSON (@json)
		with (
				brand VARCHAR(50) '$.brand', 
				color VARCHAR(50) '$.color', 
				size varchar(50) '$.size', 
				styleid VARCHAR(50) '$.styleid', 
				qty int '$.qty', 
				phone char(10) '$.phone', 
				the_action varchar(max) '$.action',
				the_session char(36) '$.Session',
				price money '$.price', 
				discount dec(3,2) '$.discount', 
				promoDiscount dec(3,2) '$.promoDiscount', 
				customerDiscount dec(3,2) '$.customerDiscount',
				uuid char(36) '$.uuid'
		) as jsonValues
		)
	, _inv (styleid, color, size, qty)  as (
		select styleid, color, size, qty  
		from s where styleid is not null
	), 
	_phone (phone, the_session) as (select phone, the_session  from s where phone is not null), 
	_action(the_action, opersign) as (select the_action, case the_action when 'remove' then -1 when 'add' then 1 end opersign
	from s where the_action is not null),
	_result (styleid, color, size, qty, phone, the_session, the_action, opersign) as (
		select styleid, color, size, qty, phone, the_session, the_action, opersign
		from _inv i
		cross apply _action a
		cross apply _phone p
	)
	select * from _result
go

		declare @json varchar(max) ;
		select @json =
		'[
			{"styleid": "19628", "color": "blUE NAVY", "size": "XXXL", "qty": "1"}, 
			{"styleid": "19996", "color": "BLU BLACK 08346", "size": "XXXL", "qty": "1"}, 
			{"action": "remove"}, 
			{"phone": "9167834248"}]';

select * from web.basket_action_fromJSON_(@json)