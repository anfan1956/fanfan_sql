select p.prefix + s.suffix from web.payment_links l join web.link_suffix s on s.linkid= l.linkid cross apply web.link_prefix p where l.orderid=77488

select * from web.link_prefix
select f.* from web.link_suffix f

declare @par varchar(max) ='{"orderid": "77505", "orderStatus": 2}'
;
declare @orderid int, @orderStatus int;
with s (orderid, orderStatus) as (
SELECT *
FROM OPENJSON(@par) WITH (
    orderid int, -- '$.orderid'
    orderStatus INT
    ))
select @orderid =s.orderid,  @orderStatus = s.orderStatus
from s;

select @orderid, @orderStatus
select *
From inv.site_reservations
where reservationid= @orderid
