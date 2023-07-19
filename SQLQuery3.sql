--select web.promocode_valid_('9167834248', '74786', 19996)
--set nocount on;declare @phone char (10) ='9167834248', @styleId int = 19996, @note varchar(max); exec web.promo_p @phone, @styleId, @note output; select @note;
go
--set nocount on;declare @phone char (10) ='9167834248', @styleId int = 19996, @note varchar(max); exec web.promo_p @phone, @styleId, @note output; select @note;
select * from web.promo_log order by 1 desc

