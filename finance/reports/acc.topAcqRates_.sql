if OBJECT_ID('acc.topAcqRates_') is not null drop function acc.topAcqRates_
go
create function acc.topAcqRates_(@date date) returns table as return
with s (registerid, bankid, receipttypeid, rate, days_off, num) as (
	select 
		a.registerid, r.bankid, a.acqTypeid, a.rate, a.days_off, 
		ROW_NUMBER() over (partition by a.registerid, a.acqTypeid order by a.datestart desc) 
	from acc.acquiring a
		join acc.registers r on r.registerid =a.registerid

	where a.datestart<=@date
)
select * from s where s.num =1
go


declare @date date = '20240224'
select * 
from acc.topAcqRates_(@date)

