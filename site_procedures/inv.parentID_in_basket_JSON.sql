if OBJECT_ID('inv.parentID_in_basket_JSON') is not null drop function inv.parentID_in_basket_JSON
go 
create function  inv.parentID_in_basket_JSON(@json varchar(max)) returns int as 

begin
declare @q int;	

with s (styleid, color, size, phone, uuid) as (	
	select styleid, color, size, phone, uuid
	from OPENJSON (@json)
	with (
			color VARCHAR(50) '$.color', 
			size varchar(50) '$.size', 
			phone char(10) '$.phone', 
			uuid varchar(max) '$.uuid', 
			styleid VARCHAR(50) '$.styleid'
			) as jsonValues
		)
, _user (phone, uuid) as (
	select 
		phone, uuid
	from s 
	where phone is not null  or uuid is not null
)
, _basket (styleid, color, size, phone, uuid) as (
	select styleid, color, size, u.phone, u.uuid
	from s
		outer apply _user u
	where styleid is not null
)
select @q = b.qty
from _basket s
	join web.baskets b on 
		b.parent_styleid=s.styleid
		and cmn.norm_(b.color ) =cmn.norm_(s.color )
		and b.size= s.size
	join web.logs l on b.logid = l.logid 
		and ( l.custid=cust.customer_id(s.phone) or l.uuid=s.uuid)
	return isnull(@q, 0)
end
go


declare @json varchar(max)
select @json =
/*
*/

--'[
--	{
--	"phone": "9167834248", 
--	"uuid": "fadd7d43-6065-45cd-a50d-670c1df19113", 
--	"procName": "insert"
--	}, {"styleid": "13530", "color": "white", "size": "1", "qty": "1"}]'

'[{"phone": "9167834248", "uuid": "7f82dede-ca47-4299-ac90-0f8ee91f38c6"}, {"styleid": 7445, "color": "ZERO", "size": "4", "qty": "1"}]'

--select inv.parentID_in_basket_JSON(@json)

--select @json =
--'{"color":"WHITE","size":"3","styleid":"13530","price":"19125","discount":"0.0","phone":"9167834248","qty":"1","promoDiscount":"0.0","uuid":"6a048147-3384-4a23-8185-7702c610860d"}'
--select inv.parentID_in_basket_JSON(@json);

declare @q int;

with s (styleid, color, size, phone, uuid) as (
	select styleid, color, size, phone, uuid
	from OPENJSON (@json)
	with (
			color VARCHAR(50) '$.color', 
			size varchar(50) '$.size', 
			phone char(10) '$.phone', 
			uuid varchar(max) '$.uuid', 
			styleid VARCHAR(50) '$.styleid'
			) as jsonValues
		)
, _user (phone, uuid) as (
	select 
		phone, uuid
	from s 
	where phone is not null  or uuid is not null
)
, _basket (styleid, color, size, phone, uuid) as (
	select styleid, color, size, u.phone, u.uuid
	from s
		outer apply _user u
	where styleid is not null
)
select @q = b.qty
from _basket s
	join web.baskets b on 
		b.parent_styleid=s.styleid
		and cmn.norm_(b.color ) =cmn.norm_(s.color )
		and b.size= s.size
	join web.logs l on b.logid = l.logid 
		and ( l.custid=cust.customer_id(s.phone) or l.uuid=s.uuid)
select isnull (@q, 0)

select inv.parentID_in_basket_JSON('[{"phone": "9167834248", "uuid": "7f82dede-ca47-4299-ac90-0f8ee91f38c6"}, {"styleid": 7445, "color": "ZERO", "size": "4", "qty": "1"}]')