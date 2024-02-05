use fanfan
go

;
if OBJECT_ID('cmn.rateOnDate_') is not null drop function cmn.rateOnDate_
go
create function cmn.rateOnDate_(@date date) returns table as return 

with s (ratedate, currencyid, rate, timeupdated, num) as (
select * , ROW_NUMBER() over (partition by _code order by Period desc) num
from CBRates.dbo.Rates r
where r.Period <=@date
)
select ratedate, currencyid, rate
from s where s.num=1
go

declare @date date = '20231231'
select * from cmn.rateOnDate_(@date)
order by 1 desc