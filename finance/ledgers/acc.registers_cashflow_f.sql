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

if OBJECT_ID('acc.registers_cashflow_f')  is not null drop function acc.registers_cashflow_f
go
create function acc.registers_cashflow_f (@date date) returns table as return
with _ext_e as (
-- extend entries to include fields from t.transactions
	select 
		e.*, t.transdate, t.amount, t.articleid, t.comment
	from acc.entries e
		join acc.transactions t on t.transactionid=e.transactionid
		join acc.entries e2 on e2.transactionid=e.transactionid and e2.is_credit <> e.is_credit
	where e.registerid is not null
)
, s (registerid, transactionid, transdate, amount, accountid, articleid, comment, personid) as (
	select 
		e.registerid, 
		e.transactionid, 
		e.transdate, 
		cast (e.amount * (1-2* e.is_credit) as money), 
		e2.accountid,
		e.articleid, 
		e.comment, 
		e2.personid
	from _ext_e e
		join acc.entries e2 on e2.transactionid=e.transactionid and e.is_credit<>e2.is_credit
		join acc.beg_entries_around_date_f(@date) d on d.registerid=e.registerid and e.transdate>=d.entrydate and num = 1
	union all 
	select 
		e.registerid, 
		e.entryid, 
		e.entrydate, 
		e.amount, 
		acc.account_id('деньги'), 
		a.articleid, 
		null, null
	from acc.beg_entries e 
		join acc.beg_entries_around_date_f(@date) d on d.entryid=e.entryid
		cross apply acc.articles a
	where 
		a.article = 'НАЧАЛЬНЫЕ ОСТАТКИ'
)

select 
	s.registerid, 
	s.transactionid, 
	cast (s.transdate as datetime) дата, 
	s.amount сумма, 
	a.account план_счетов, 
	ar.article статья, 
	sum (s.amount) over (partition by s.registerid order by s.transdate, transactionid) reg_total, 
	c.contractor банк, 
	c2.contractor клиент,
	r.account счет_банк, 
	isnull(p.lfmname, '') получатель, 
	isnull(s.comment, '') комментарий
from s
	join acc.accounts a on a.accountid=s.accountid
	join acc.articles ar on ar.articleid=s.articleid
	join acc.registers r on s.registerid = r.registerid
	join org.contractors c on c.contractorID=r.bankid
	join org.contractors c2 on c2.contractorID = r.clientid
	left join org.persons p on p.personID = s.personid
go

--declare  @registerid int = 7
declare @date date = '20221128';
select * from acc.registers_cashflow_f(@date)
order by 3;
go
declare @date date = '20221128';
select * from acc.beg_entries_around_date_f(@date)