
if OBJECT_ID('web.stylesForEvent_f') is not null drop function web.stylesForEvent_f
go
create function web.stylesForEvent_f (@eventid as int) returns varchar(max) as
begin
declare @styles varchar(max);


select @styles =
	STUFF((
        select ',' + cast (s.styleid as varchar(max))  
from web.promo_events w
	join web.promo_styles_discounts s on s.eventid=w.eventid
		and w.eventid = @eventid
FOR XML PATH('')
	),1,1,'') 
return @styles	
end
go

select web.stylesForEvent_f(1)
