if OBJECT_ID('web.promo_event_close') is not null drop proc web.promo_event_close
go
create proc web.promo_event_close @eventid int as
	set nocount on;
	update p set p.eventClosed= 'True'
	from web.promo_events p where p.eventid =@eventid

	return @eventid
go

set nocount on; declare @r int, @eventid int = 1; 
--exec @r = web.promo_event_close @eventid = @eventid; select @r

select * 
from web.promo_events e 
	join web.promo_styles_discounts d on d.eventid=e.eventid
where e.eventClosed= 'false'

select eventid from web.promo_events e where e.eventClosed='false'