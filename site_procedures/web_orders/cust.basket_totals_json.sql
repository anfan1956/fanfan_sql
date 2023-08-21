if OBJECT_ID('cust.basket_totals_json') is not null drop function cust.basket_totals_json
go
create function cust.basket_totals_json(@phone char(10)) returns varchar(max) as
begin
	declare @totals varchar(max);
		with s (штук, итого) as (
		select sum (qty), format(sum(total), '#,##0') 
		from web.customer_basket_(@phone)
		)
	select @totals =(select штук, итого from s for json path)
	return @totals
end
go
declare @phone char(10) = '9167834248';
	declare @totals varchar(max);
		with s (pcs, total) as (
		select sum (qty), sum(total) 
		from web.customer_basket_(@phone) 
		)
select @totals =(select  pcs, total from s for json path)
select cust.basket_totals_json(@phone)
select web.basketContent_(@phone)



