if OBJECT_ID('acc.invoices_v') is not null drop view acc.invoices_v
go
create view acc.invoices_v as

with _payments(invoiceid, amount) as (
	select p.invoiceid, SUM(p.amount)
	from acc.invoices_payments p
	group by p.invoiceid
)
select
	i.invoiceid, 
	cast(t.transdate as datetime) дата_инвойса, 
	c2.contractor поставщик,
	i.documentNum [№_инвойса],
	cr.currencycode валюта,
	t.amount  сумма,
	t.amount - isnull(pm.amount, 0)  остаток,
	t.comment описание, 
	cast(i.datedue as datetime) оплатить_до,
	format(i.periodDate, 'MMM - yyyy', 'ru') за_период,
	a.article статья, 
	c.clientRus плательщик,
	p.lfmname оператор 
from acc.transactions t
	join acc.invoices i on i.invoiceid = t.transactionid
	join org.persons p on p.personID=t.bookkeeperid
	join cmn.currencies cr on cr.currencyID = i.currencyid
	join acc.articles a on a.articleid=t.articleid
	join org.clients c on c.clientID=t.clientid
	join org.contractors c2 on c2.contractorID = i.vendorid
	left join _payments pm on pm.invoiceid=i.invoiceid
where t.amount - isnull(pm.amount, 0) <>0
go

select * from acc.invoices_v order by 'плательщик'