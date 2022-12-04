use fanfan
go

if OBJECT_ID('acc.payments_date_f') is not null drop function  acc.payments_date_f
go 
create function acc.payments_date_f(@date date) returns table as return

with s (id, дата, reg_id, плательщик, статья, [план счетов], получатель, документ, банк, [счет/банк], валюта, сумма, оператор) as (
select 
	t.transactionid, 
	cast(t.transdate as datetime) transdate,
	e.registerid,
	c2.contractor, 
	a.article, 
	ac.account, 
	isnull(c3.contractor, p.lfmname), 
	t.comment, c.contractor, 
	r.account, cr.currencycode, 
	(1 - 2 * e.is_credit) * t.amount , 
	p2.lfmname
from acc.transactions t
	join acc.entries e on e.transactionid =t.transactionid and e.registerid is not null
	join acc.registers r on r.registerid= e.registerid
	join cmn.currencies cr on cr.currencyID= r.currencyid
	join org.contractors c on r.bankID=c.contractorID
	join org.contractors c2 on c2.contractorID= r.clientid
	join acc.articles a on a.articleid=t.articleid
	join acc.accounts ac on ac.accountid=a.accountid
	join acc.entries e2 on e2.transactionid =e.transactionid and e2.is_credit <> e.is_credit
	left join org.contractors c3 on c3.contractorID=e2.contractorid
	left join org.persons p on p.personID = e2.personid
	join org.persons p2 on p2.personID= t.bookkeeperid
where t.transdate= isnull(@date, getdate())
)
select * from s
go
declare @date date = '20221201';
select * from acc.payments_date_f(@date)


if OBJECT_ID('acc.payments_v') is not null drop view acc.payments_v
go
create view acc.payments_v as
with _e(entryid) as (
	select 
		e.entryid
	from acc.transactions t
		join acc.entries e on e.transactionid =t.transactionid 
			and e.is_credit = 'True'
			and e.accountid = acc.account_id('деньги')
	union all 
	select 
		e.entryid
	from acc.transactions t
		join acc.entries e on e.transactionid =t.transactionid 
			and e.is_credit = 'false'
			and e.accountid = acc.account_id('деньги')
) 
, _f  as (
select 
	e.transactionid,
	cast(t.transdate as datetime) дата,
	c3.contractor клиент, 
	a.article статья, 
	ac.account план_счетов, 
	isnull(c.contractor, p.lfmname) контрагент,
	t.comment документ,	
	c2.contractor банк, 
	r.account счет_банк, 
	cr.currencycode валюта, 
	t.amount * (1- 2* e.is_credit ) сумма, 
	per.lfmname оператор, 
	r.registerid, 
		DATEPART(YYYY, transdate) год, 
		DATEPART(MM,transdate) месяц
from acc.entries e 
	join _e on _e.entryid=e.entryid
	join acc.transactions t on t.transactionid = e.transactionid
	join acc.articles a on a.articleid=t.articleid
	join acc.entries ec on ec.transactionid=e.transactionid and ec.entryid<>e.entryid
	left join org.persons p on ec.personid= p.personID
	join acc.accounts ac on ac.accountid=ec.accountid
	left join org.contractors c on ec.contractorid=c.contractorID
	join acc.registers r on r.registerid=e.registerid
	join org.contractors c2 on c2.contractorID=r.bankid
	join org.contractors c3 on c3.contractorID=r.clientid
	join cmn.currencies cr on cr.currencyID = t.currencyid
	join org.persons per on per.personID = t.bookkeeperid
)
select * from _f
go

select * from acc.payments_v
