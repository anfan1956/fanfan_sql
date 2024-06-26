USE [fanfan]
GO
if OBJECT_ID('acc.registers_cashflow_f') is not null drop function acc.registers_cashflow_f
go
create function acc.registers_cashflow_f(@date date) returns table as return

with 
--this CTE is relevant to all transactions 
_dates (registerid, entrydate) as (
	select f.registerid, f.entrydate
	from acc.beg_entries_around_date_f(@date) f
		join acc.registers r on r.registerid= f.registerid
)
, _registers (registerid) as (select registerid from acc.registers)
-- this CTE may not be relevant at all now it is used as a filter
--, _trans (transid, registerid) as (
--	select transactionid, r.registerid
--	from acc.entries e
--	join _registers r on r.registerid = e.registerid
--)
-- this CTE is relevant to acquiring (revenue) part of Union all
, _seed (accountid, factor, dayshift) as ( 
	select acc.account_id('выручка'), -1.0000, 0
	union all 
	select acc.account_id('эквайринг'), 1.0000, 0
	union all
	select acc.account_id('эквайринг'), -1.0000, 1
	union all
	select acc.account_id('фин. расходы'), null, 1
	)
, s as (
	select 
		s.saleID, 
		s.divisionID, 
		s.customerID, 
		s.salepersonID, 
		sr.amount * iif(t.transactiontypeID=13, -1, 1) amount, 
		sr.registerid,
		t.transactiondate, 
		dt.entrydate be_date, 
		ra.acqTypeid, 
		t.transactiontypeID, 
		rate, 
		r.currencyid, 
		ROW_NUMBER () over (partition by sr.saleid, sr.registerid, a.acqtypeid order by a.datestart desc) num
	from inv.sales_receipts sr
		join inv.transactions t on t.transactionID = sr.saleID
		join inv.sales s on s.saleID=sr.saleID
		join acc.registers r on r.registerid=sr.registerid
		join acc.rectypes_acqTypes ra on ra.receipttypeid=sr.receipttypeID
		join acc.acquiring a on a.acqTypeid= ra.acqTypeid 
			and a.registerid = sr.registerid 
			and a.datestart<=t.transactiondate
		join _dates dt on dt.registerid= sr.registerid and t.transactiondate>=DATEADD(DD, -a.days_off, dt.entrydate)
), 
_sales_cf (registerid, saleid, transdate, be_date,  amount, accountid, articleid, comment, salespersonid) as (
select 
	s.registerid, 
	s.saleID, 
	DATEADD(DD,sd.dayshift, s.transactiondate) transdate, 
	be_date, 
	-s.amount * isnull(factor, s.rate * iif(s.transactiontypeid = 13, 0, 1)) amount,
	sd.accountid, 
	acc.article_id('РОЗНИЧНАЯ ВЫРУЧКА'), 
	'выручка',
	salepersonID
from s 
	join _registers r on r.registerid=s.registerid
	cross apply _seed sd
where num =1 
)
, _united(registerid, transactionid, transdate, be_date, amount, accountid, articleid, comment, contractorid) as (
select * 
from _sales_cf f
where f.transdate >= f.be_date 
union all
select 
	e.registerid, 
	t.transactionid, 
	t.transdate,
	dt.entrydate, 
	t.amount * (1- 2 * e.is_credit) amount, 
	e2.accountid, 
	t.articleid, 
	t.comment, 
	isnull(e2.personid, e2.contractorid)
from  acc.transactions t 
	join acc.entries e on e.transactionid = t.transactionID 
	join acc.entries e2 on e2.transactionid=e.transactionid and e2.is_credit<>e.is_credit
	join acc.registers r on r.registerid  = e.registerid
	left join acc.registers r2 on r.registerid  = e2.registerid
	join _dates dt on dt.registerid= e.registerid and t.transdate>=dt.entrydate

union all
select 
	f.registerid, 
	f.entryid, 
	f.entrydate, 
	f.entrydate, 
	f.amount, 
	acc.account_id('деньги') accountid, 
	acc.article_id('НАЧАЛЬНЫЕ ОСТАТКИ'), 
	'нач. остатки', 
	r.clientid
--	f.bookkeeperid 
from acc.beg_entries_around_date_f (@date) f
	join acc.registers r on r.registerid = f.registerid	
)
, _final 
	(registerid, transactionid, дата, дата_но, сумма, currencyid, план_счетов, статья, банк, 
		клиент, счет_банк, получатель, комментарий  ) as (
select 
	r.registerid, 
	transactionid, 
	transdate, 
	be_date, 
	amount, 
	r.currencyid, 
	a.account, 
	ar.article, 
	c.contractor, 
	c2.contractor, 
	r.account,  
	isnull (isnull(p.lfmname, c3.contractor), c2.contractor),
	u.comment
from _united u
	join acc.accounts a on a.accountid=u.accountid
	join acc.articles ar on ar.articleid=u.articleid
	join acc.registers r on r.registerid= u.registerid
	join org.contractors c on c.contractorid=r.bankid
	join  org.contractors c2 on c2.contractorid=r.clientid
	left join org.contractors c3 on u.contractorid = c3.contractorID
	left join org.persons p on p.personID = u.contractorid
)
select 
	registerid, 
	transactionid id, 
	cast(cast(дата as date) as datetime) дата, 
	cast(дата_но as datetime) дата_но, 
	сумма, 
	currencyid, 
	план_счетов, 
	статья, 
	банк, 
	клиент, 
	счет_банк, 
	получатель, 
	комментарий  
from _final
go

declare @date date = '20221215'; 

select * from acc.registers_cashflow_f(@date) 
where id = 1463
select * from acc.registers_cashflow_old_f(@date) 
where registerid = 19