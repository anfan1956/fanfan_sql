if OBJECT_ID('web.actionFinish_date') is not null drop function web.actionFinish_date
go 
create function web.actionFinish_date () returns varchar (max) as 
begin
	declare @date_string varchar(max);
		select @date_string = format (datefinish, 'dd MMMM yyyy', 'ru-ru')
		from web.promo_events e 
		where	
			cast(getdate() as date) between e.datestart and e.datefinish 
			and eventClosed = 'False'
	return isnull(@date_string, 'Сейчас нет промо-акций')
end
go

select web.actionFinish_date()
select * 
--update e set e.datefinish= DATEADD(dd, 20, datefinish)
from web.promo_events e
