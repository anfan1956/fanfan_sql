declare @json varchar(max) = 
'[{"phone": "9167834248", "uuid": "db0cd471-e7f0-41d4-bec2-7fafd2845948"}, {"styleid": 13530, "color": "WHITE", "size": "1", "qty": "1"}]'
;
declare @phone char(10) = '9167834248', 
	@uuid char(36) = 'fadd7d43-6065-45cd-a50d-670c1df19113';

if OBJECT_ID('web.basket_this_total_') is not null drop function web.basket_this_total_
go
create function web.basket_this_total_(@json varchar(max)) returns varchar (max) as 
begin
	declare @totals varchar(max);
	with s (styleid, color, size, phone, uuid) as (
		select styleid, color, size, phone, uuid from openjson(@json)
			with (
				styleid int '$.styleid', 
				color varchar(max) '$.color', 
				size varchar(max) '$.size', 
				phone varchar(max) '$.phone', 
				uuid varchar(max) '$.uuid'
			)
	)
	, _user (phone, uuid) as (
		select phone, uuid from s where phone is not null) 
	, _product (styleid, color, size, phone, uuid) as (
		select styleid, color, size, u.phone, u.uuid
		from s 
			cross apply _user u
		where styleid is not null
	)
	select @totals = (
	select isnull((
		select b.qty this  
		from _product p
			join web.baskets b on b.parent_styleid=p.styleid
				and cmn.norm_(p.color)=cmn.norm_(b.color)
				and p.size = b.size), 0
	) this, 
	(select isnull((
		select sum(b.qty) 
		from web.baskets b
			join web.logs l on l.logid=b.logid
			join _product p on cust.customer_id(p.phone)= l.custid
				or l.uuid=p.uuid	
	), 0)) total
	for json path)
	return @totals
end
go

declare @json varchar(max) = 
'[{"phone": "9167834248", "uuid": "db0cd471-e7f0-41d4-bec2-7fafd2845948"}, {"styleid": 13530, "color": "WHITE", "size": "4", "qty": "1"}]'
select web.basket_this_total_(@json)
