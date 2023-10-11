--select * from web.basket;select * from web.basketLogs;
if OBJECT_ID('web.customer_basket_') is not null drop function web.customer_basket_
go 
create function web.customer_basket_ (@phone char(10)) returns table as 
	return
		select * from web.customer_basket_v v where v.custid= cust.customer_id(@phone)
go 



