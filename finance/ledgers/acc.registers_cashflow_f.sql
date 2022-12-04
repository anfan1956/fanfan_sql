
if OBJECT_ID('acc.registers_cashflow_f')  is not null drop function acc.registers_cashflow_f
go
create function acc.registers_cashflow_f (@date date) returns table as return
with _ordered (registerid, entrydate, entryid, num) as (
	select 
		b.registerid,
		b.entrydate, 
		b.entryid, 
		ROW_NUMBER() over(partition by registerid order by entrydate desc)  num
	from acc.beg_entries b
	where entrydate <=@date
)
, _ext_e as (
-- extend entries to include fields from t.transactions
	select 
		e.*, t.transdate, t.amount, t.articleid
	from acc.entries e
		join acc.transactions t on t.transactionid=e.transactionid
	where e.registerid is not null
)
, s (registerid, transactionid, transdate, amount, accountid, articleid) as (
	select 
		e.registerid, 
		e.transactionid, 
		e.transdate, 
		cast (e.amount * (1-2* e.is_credit) as money), 
		e2.accountid,
		e.articleid
	from _ext_e e
		join acc.entries e2 on e2.transactionid=e.transactionid and e.is_credit<>e2.is_credit
		join _ordered d on d.registerid=e.registerid and e.transdate>=d.entrydate and num = 1
--		join acc.beg_entries_after_f(@date) d on d.registerid=e.registerid and e.transdate>=d.entrydate


	union all 
	select 
		e.registerid, 
		e.entryid, 
		e.entrydate, 
		e.amount, 
		acc.account_id('деньги'), 
		a.articleid
	from acc.beg_entries e 
		join acc.beg_entries_after_f(@date) d on d.entryid=e.entryid
		cross apply acc.articles a
	where 
		a.article = 'НАЧАЛЬНЫЕ ОСТАТКИ'
)

select 
	s.registerid, s.transactionid, s.transdate, s.amount, 
	a.account, 
	ar.article
	, sum (s.amount) over (partition by s.registerid order by s.transdate, transactionid) reg_total
from s
	join acc.accounts a on a.accountid=s.accountid
	join acc.articles ar on ar.articleid=s.articleid
go
declare  @registerid int = 7
declare @date date = '20221130';
select * from acc.registers_cashflow_f(@date)
order by 3;

if OBJECT_ID('acc.beg_entries_after_f') is not null drop function acc.beg_entries_after_f
go
create function acc.beg_entries_after_f(@date date) returns table as return
	with _ordered (registerid, entrydate, entryid, num) as (
		select 
			b.registerid,
			b.entrydate, 
			b.entryid, 
			ROW_NUMBER() over(partition by registerid order by entrydate desc)  num
		from acc.beg_entries b
		where entrydate <=@date
	)
	select registerid, entryid, entrydate, num from _ordered where num =1;

go

