﻿
if OBJECT_ID('web.promocode_valid_') is not null drop function web.promocode_valid_
go
create function web.promocode_valid_(@cust_phone char(10), @promocode varchar(6), @styleid int) returns bit as 
begin
declare @valid bit;

select @valid =1  from web.promo_log 
where 
	custid= cust.customer_id(@cust_phone) 
	and used = 'false' 
	and promocode=@promocode
	and styleid = @styleid

return isnull(@valid, 0)
end
go

declare @phone char(10) = '9167834248', @promocode varchar(6)= '26241', @styleid int = 19628
select web.promocode_valid_(@phone, @promocode, @styleid)
select * from web.promo_log where custid =17448 and used = 'False'
