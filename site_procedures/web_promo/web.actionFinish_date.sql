if OBJECT_ID('web.actionFinish_date') is not null drop function web.actionFinish_date
go 
create function web.actionFinish_date () returns varchar (max) as 
begin
	declare @date_string varchar(max);
		select @date_string = format (datefinish, 'dd MMMM', 'ru-ru')
		from web.promo_events e 
		where	
			cast(getdate() as date) between e.datestart and e.datefinish 
			and eventClosed = 'False'
	select @date_string = (select isnull(@date_string, 'past') last_date for json path)
	return @date_string

end
go

select web.actionFinish_date()
select * 
--update e set e.datefinish= DATEADD(dd, 20, datefinish)
from web.promo_events e

declare @finish varchar(max)

select @finish = format (datefinish, 'dd MMMM yyyy', 'ru-ru')
		from web.promo_events e 
		where	
			cast(getdate() as date) between e.datestart and e.datefinish 
			and eventClosed = 'False'
select @finish


select e.datefinish 
--update e set e.datefinish = DATEADD(dd, -10, datefinish)
from web.promo_events e