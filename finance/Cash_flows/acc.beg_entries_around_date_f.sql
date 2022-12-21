if OBJECT_ID('acc.beg_entries_around_date_f ') is not null drop function acc.beg_entries_around_date_f 
go
create function acc.beg_entries_around_date_f (@date date) returns table as return
with _before as (
select b.registerid, b.entrydate, b.entryid, b.amount, b.bookkeeperid, 
	ROW_NUMBER() over(partition by b.registerid order by b.entrydate desc) num
from acc.beg_entries b
where b.entrydate <=@date
)
, _before_1 as (
	select *
	from _before b where num = 1
)
, _after as (
	select distinct a.registerid
	from acc.registers a
		left join acc.beg_entries b on b.registerid = b.registerid
	except select registerid from _before_1
)
, _all_after as (
	select a.registerid, isnull(b.entrydate, @date) entrydate, isnull(b.entryid, 0) entryid, b.amount, b.bookkeeperid,
			ROW_NUMBER() over(partition by b.registerid order by b.entrydate) num
	from _after a 
		left join acc.beg_entries b on b.registerid =a.registerid
)
, _combined as (
	select * from _all_after where num =1
	union all 
	select * from _before_1
)
select * from _combined c 
go

declare @date date = '20221128';
select * from acc.beg_entries_around_date_f(@date)
order by 1