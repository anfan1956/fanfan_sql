if OBJECT_ID('cust.basket_totals_json') is not null drop function cust.basket_totals_json
go
create function cust.basket_totals_json(@json varchar(max)) returns varchar(max) as
begin
	declare @totals varchar(max);
;
	with s (phone, uuid) as 
		(
			select phone, Session from OPENJSON(@json)
			with (
				phone char(10) '$.phone', 
				Session char(36) '$.Session'
			)		
		)
select @totals = (
select 
	isnull(sum(qty), 0) штук, isnull(cast(round(sum(total), 0) as int), 0) итого
from web.customer_basket_v v
	join s on v.custid = cust.customer_id(s.phone) or v.uuid=s.uuid
	--having sum(qty) is not null
for json path, INCLUDE_NULL_VALUES
)

return @totals
end
go



declare @json varchar(max) = '{"phone": null, "Session": "103ef4dc-5ef4-4c0d-ac16-c832ca67c081"}'
select cust.basket_totals_json (@json)


select web.basketContent_('9167834248')