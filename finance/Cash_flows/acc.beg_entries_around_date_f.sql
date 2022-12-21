if OBJECT_ID('acc.beg_entries_around_date_f ') is not null drop function acc.beg_entries_around_date_f 
go
create function acc.beg_entries_around_date_f (@date date) returns table as return
	with _before as (
		select distinct registerid from acc.beg_entries e where e.entrydate<=@date
	)
	, _after as (
		select distinct registerid from acc.beg_entries 
		except select registerid from _before
	)
	, _ordered (registerid, entrydate, entryid, amount, num, bookkeperid) as (
		select 
			b.registerid,
			b.entrydate, 
			b.entryid, 
			b.amount, 
			ROW_NUMBER() over(partition by registerid order by entrydate desc), 
			b.bookkeeperid
		from acc.beg_entries b
		where entrydate <=@date
	union all 
		select 
			b.registerid,
			b.entrydate, 
			b.entryid,
			b.amount, 
			ROW_NUMBER() over(partition by b.registerid order by entrydate), 
			b.bookkeeperid
		from acc.beg_entries b
			join _after be on be.registerid=  b.registerid
	)
	select o.registerid, o.entrydate, o.entryid, o.amount, o.bookkeperid, o.num 
	from _ordered o  where num =1;
	go

declare @date date = '20221128';
select * from acc.beg_entries_around_date_f(@date)