use fanfan
go

if OBJECT_ID('web.promo_current_ends_') is not null drop function web.promo_current_ends_
go
create function web.promo_current_ends_() returns varchar(max) as 
begin
declare @enddate varchar(max)
select @enddate =  format ( datefinish, 'dd.MM.yyyy', 'ru-ru') from web.promo_events where cast (getdate() as date) between datestart and datefinish
return @enddate
end
go

select web.promo_current_ends_()