--select * from web.basket;select * from web.basketLogs;
if OBJECT_ID('web.customer_basket_') is not null drop function web.customer_basket_
go 
create function web.customer_basket_ (@phone char(10)) returns table as 
	return
		select * from web.customer_basket_v v where v.custid= cust.customer_id(@phone)
go 


if OBJECT_ID('web.basketContent_') is not null drop function web.basketContent_
go
create function web.basketContent_(@phone char(10)) returns varchar(max) as
begin
declare @content varchar (max)
	select @content = (
		select 
			brand марка, parentid модель, category категория,
			color цвет, size размер, 
			format(price, '#,##0') цена, 
			format(discount, '#,##0%') скидка, 
			format(promoDiscount, '#,##0%') промо, qty кол , format(total, '#,##0') всего 
		from web.customer_basket_(@phone) for json path)
		if @content is null
		select @content= (select 'Пустая' корзина for json path)
return @content
end
go




if OBJECT_ID('inv.sortid_fromJson_') is not null drop function inv.sortid_fromJson_
--go
--create function inv.sortid_fromJson_(@js_string varchar(max)) returns int as
--begin
--declare @code int;
--select @code = inv.barcode_sortid_(styleid, color, size) 
--from OPENJSON (@js_string)
--with (
--				color VARCHAR(50) '$.color', 
--				size varchar(50) '$.size', 
--				styleid VARCHAR(50) '$.styleid_parent', 
--				qty int '$.qty', 
--				phone char(10) '$.phone', 
--				price money  '$.price', 
--				discount dec(3,2) '$.discount', 
--				promoDiscount dec(3,2) '$.promoDiscount', 
--				customerDiscount dec(3,2) '$.customerDiscount',
--				uuid char(36) '$.uuid'

--		) as jsonValues
--return @code
--end
--go

--declare 
--	@color varchar(max) = 'ANGEL', 
--	@size varchar(max) = 'XXL', 
--	@styleid varchar (max) = '19628'
--declare @sortid int = inv.barcode_sortid_(@styleid, @color, @size);
--declare @myStr varchar(max)
--set @myStr = '{"size": "XXL", "color": "ANGEL", "phone": "9167834248", "styleid_parent": "19628"}';


--select * from inv.bc_sortid_qtys (@sortid)
--select * from web.customer_basket_v
--select count(*) from web.customer_basket_(@phone) 
--select sum (qty) from web.customer_basket_(@phone) 
--select sum(qty) from web.customer_basket_(@phone) b where b.sort_barcodeID=inv.sortid_fromJson_(@myStr)

--select * from web.customer_basket_v
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



