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
		from web.customer_basket_(@phone)
		for json path)
		if @content is null
		select @content= (select 'Пустая' корзина for json path)
return @content
end
go
declare @phone char (10)= '9167834248';
select web.basketContent_(@phone)
select * from web.customer_basket_(@phone)