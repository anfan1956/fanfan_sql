declare @json varchar(max) = 
'[
	{"phone": "9167834248", "Session": "00f8ec9f-38c1-4ae1-9b8c-8909984e6bd5", "procName": "calculate"}, 
	{"styleid": "13530", "color": "AMBER", "size": "2", "price": "19125", "discount": "0.0", "promo": "0.0", "qty": "1"}, 
	{"styleid": "13530", "color": "WHITE", "size": "3", "price": "19125", "discount": "0.0", "promo": "0.0", "qty": "2"}
]'


if OBJECT_ID ('web.basket_toPay_json') is not null drop function web.basket_toPay_json
go
create function web.basket_toPay_json(@json varchar(max)) returns varchar(max) as
begin
declare @out varchar(max);
with s ( styleid, color, size, qty, phone) as (
select  styleid, color, size, qty, phone
from OPENJSON (@json)
		with (
				brand VARCHAR(50) '$.brand', 
				color VARCHAR(50) '$.color', 
				size varchar(50) '$.size', 
				styleid VARCHAR(50) '$.styleid', 
				qty int '$.qty', 
				phone char(10) '$.phone', 
				price money  '$.price', 
				discount dec(3,2) '$.discount', 
				promoDiscount dec(3,2) '$.promoDiscount', 
				customerDiscount dec(3,2) '$.customerDiscount',
				uuid char(36) '$.uuid'
		) as jsonValues
		)
, _phone  as (select phone from s where phone is not null )
 , f as (select s.styleid, s.color, s.size, s.qty, p.phone
	 from s 
		cross apply _phone p 
	 where s.phone is null
)
, _logs  (parent_styleid, color, size, price, discount, promoDiscount, customerDiscount, qty) as 
	(
		select parent_styleid, color, size, price, discount, a.promo_discount, null customerDiscount, qty
		from web.baskets b
			join inv.styles_catalog_v v on v.styleid=b.parent_styleid
			left join web.styles_discounts_active_ a on a.styleid=b.parent_styleid
			join web.logs l on b.logid=l.logid
			cross apply _phone p
			where l.custid = cust.customer_id(p.phone)
		group by parent_styleid, color, size, price, discount, a.promo_discount, qty
	)

select @out =(
select  
	format(sum (f.qty * price * (1 - isnull(discount, 0))* (1-isnull(promoDiscount, 0))* (1-isnull(customerDiscount, 0))), '#,##0')
	toPay
from _logs l
	join f on f.styleid=l.parent_styleid
		and replace(f.color, ' ', '')= replace(l.color, ' ', '') 
		and replace(f.size, ' ', '')= replace(l.size, ' ', '')	
	
	for json path);
	
return @out
end
go

declare @json varchar(max) = 
'[
	{"phone": "9167834248", "Session": "00f8ec9f-38c1-4ae1-9b8c-8909984e6bd5", "procName": "calculate"}, 
	{"styleid": "13530", "color": "AMBER", "size": "2", "price": "19125", "discount": "0.0", "promo": "0.0", "qty": "1"}, 
	{"styleid": "13530", "color": "WHITE", "size": "3", "price": "19125", "discount": "0.0", "promo": "0.0", "qty": "2"}
]'

select web.basket_toPay_json(@json)
--select web.basket_toPay_json('[{"phone": "9167834248", "Session": "c4c841d1-2d31-4323-8795-991ce6e5d390", "action": "calculate"}, {"styleid": "13530", "color": "WHITE", "size": "4", "qty": "5"}]')
