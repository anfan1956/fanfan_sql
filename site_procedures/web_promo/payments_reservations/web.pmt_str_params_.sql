 
--declare @string ='orderNumber': '78141/4', 'description': 'order # 78141', 'amount': '100', 'timeOutSec': '30000', 'phone': '9167834248', 'email': 'af.fanfan.2012@gmail.com'


select v.* 
from web.active_orders_v v
	
where id_заказа = 78141


if OBJECT_ID('web.pmt_str_params_') is not null drop function web.pmt_str_params_
go 
create function web.pmt_str_params_(@orderid int, @timeOutSec int, @segid int) returns varchar(max) as
begin
	declare 
		@str varchar(max), 
		@phone char(10)= (select  cust.prime_phone_f(v.id_клиента) from web.active_orders_v v where v.id_заказа=@orderid);		
		with s as (
		select distinct 
			CONCAT_WS('-', @orderid,  @segid) orderNumber, 
			CONCAT_WS(' # ', 'order',  @orderID) description, 
			100 amount, 
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
--	declare @seq table (seqid int);
--	insert @seq  select next value for web.ordersSequence;
--declare @tag int =(select seqid from @seq)
	
declare 
	@orderID int = 78383, 
	@timeOutSec int = 30000, 
	@phone char(10) = '9167834248'

select web.pmt_str_params_(@orderID, @timeOutSec, next value for web.ordersSequence)

--select web.pmt_str_params_(78141,900, next value for web.ordersSequence)

select * 
--update c set c.connect = 'sasha@sasha.int'
from cust.connect c 
	where 
		c.personID = cust.customer_id(@phone)
		and connecttypeID = 4
order by 1 desc

