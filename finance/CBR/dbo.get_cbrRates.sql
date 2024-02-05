use CBRates;
go

if OBJECT_ID ('dbo.get_cbrRates') is not null drop proc dbo.get_cbrRates
go
create proc dbo.get_cbrRates @json varchar(max) as
begin
	with s (_Code, _Rate, Period, time_updated) as (
		select 
			cr.currencyID, rate, cast(getdate() as date), CURRENT_TIMESTAMP
		from  openJson(@json) 
		with (
			code VARCHAR(50) '$.currency', 
			rate decimal(10, 4) '$.rate' 
		) as jsonValues
		join dbo.currencies cr on cr.currencyCode=code
	)
	merge dbo.Rates as t using s
	on t.Period = s.Period 
		and t._Code = s._Code
	when not matched then 
	insert (Period, _Code, _Rate, time_updated)
	values (Period, _Code, _Rate, time_updated);

end
go

set nocount on; 

declare @json varchar(max); 
select @json = 
	'[
		{"currency": "USD", "rate": 91.5823}, 
		{"currency": "EUR", "rate": 99.134}, 
		{"currency": "GBP", "rate": 115.5036}, 
		{"currency": "AUD", "rate": 60.2978}, 
		{"currency": "RUR", "rate": 1}
	]'; 
--exec dbo.get_cbrRates @rates
	with s (_Code, _Rate, Period, time_updated) as (
		select 
			cr.currencyID, rate, cast(getdate() as date), CURRENT_TIMESTAMP
		from  openJson(@json) 
		with (
			code VARCHAR(50) '$.currency', 
			rate decimal(10, 4) '$.rate' 
		) as jsonValues
			join dbo.currencies cr on cr.currencyCode=code
	)

select * from s


select * 
--delete
from dbo.Rates 
where Period = cast(getdate() as date)
--order by 1 desc

