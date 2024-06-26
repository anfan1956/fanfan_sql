USE CBRates
go


--эта процедура писалась для того, чтобы брать курсы из ЦБ

if OBJECT_ID ('dbo.cbr_rates_p2') is not null drop proc dbo.cbr_rates_p2
if TYPE_ID('dbo.rates_type') is not null drop type dbo.rates_type
go
create type dbo.rates_type as table (code char(3), rate decimal(10, 4))
go
create proc dbo.cbr_rates_p2 @c_rates dbo.rates_type readonly, @time datetime, @date date as
set nocount on;
	begin;
		declare @r int;
		with s (Period, _Code, _Rate, time_updated)  as (
			select @date, cc.Code, r.rate, @time
			from @c_rates r
				join dbo.CurrencyCodes cc on cc.Currency=r.code
		)
		merge dbo.Rates as t using s
		on 
			t.Period=s.Period and 
			t._Code=s._Code
		when matched then 
			update set 
				_Rate=s._Rate,
				time_updated=s.time_updated

		when not matched then 
			insert (Period, _Code, _Rate, time_updated)
			values (cast(time_updated as date), _Code, _Rate, time_updated)		
	;
		select @r= @@ROWCOUNT;
	end
go 


--declare @r int, @rates dbo.rates_type, @the_time datetime = current_timestamp, @the_date date =  '20231109'; 
--insert @rates values ('USD',  92.1973), ('EUR',  98.4403), ('GBP',  113.4488); exec @r = dbo.cbr_rates_p2 @rates, @the_time, @the_date; select @r 

select * from dbo.Rates order by 1 desc