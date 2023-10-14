 if OBJECT_ID('web.pmt_str_params_') is not null drop function web.pmt_str_params_
go 
create function web.pmt_str_params_(@full varchar(max), @orderid int, @timeOutSec int, @segid int) returns varchar(max) as
begin
	declare 
		@str varchar(max), 
		@phone char(10)= (select distinct cust.prime_phone_f(v.id_клиента) from web.active_orders_v v where v.id_заказа=@orderid);		
		with s as (
		select distinct 
			CONCAT_WS('-', @orderid,  @segid) orderNumber, 
			CONCAT_WS(' # ', 'order',  @orderID) description, 
			case @full 
				when 'alfabank' then 100 
				when 'tinkoff' then 150 
				when 'complete' then
					cast(ROUND( sum (amount), 0) * 100 as int) end amount, 					
			@timeOutSec timeOutSec,
			--cust.prime_phone_f(v.id_клиента) phone, 
			@phone phone, 
			cust.customer_mail(@phone) email
		from web.active_orders_v v
		where id_заказа =@orderID
		)
		select @str = (select s.orderNumber, description, amount, timeOutSec, phone, email from s
		for json path)
	return @str
end
go


select web.pmt_str_params_('tinkoff', 78604, 900, next value for web.ordersSequence)
select web.pmt_str_params_('tinkoff', 79052, 900, next value for web.ordersSequence)
