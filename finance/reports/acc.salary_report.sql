use fanfan
go

-- выделил постирование инвойсов в отдельный файл ...\finance\invoices\acc.invoicesPost_p.sql
-- smth did not work

if OBJECT_ID('acc.salary_report_v') is not null drop view acc.salary_report_v
go 
create view acc.salary_report_v as
	select t.transactionid, transdate, a.article, comment, amount * ( 2 * is_credit - 1) amount, lfmname 
	from acc.transactions t
		join acc.entries e on e.transactionid =t.transactionid 
		join acc.articles a on a.articleid=t.articleid
		join org.persons p on p.personID = e.personid
	where e.accountid = acc.account_id('зарплата к оплате')
go



if OBJECT_ID('acc.invoices_v') is not null drop view acc.invoices_v
go
create view acc.invoices_v as
select
	i.invoiceid, 
	cast(t.transdate as datetime) дата_инвойса, 
	c2.contractor поставщик,
	i.documentNum [№_инвойса],
	cr.currencycode валюта,
	t.amount сумма,
	t.comment описание, 
	cast(i.datedue as datetime) оплатить_до,
	format(i.periodDate, 'MMM - yyyy', 'ru') за_период,
	a.article статья, 
	c.contractor плательщик,
	p.lfmname оператор 
from acc.transactions t
	join acc.invoices i on i.invoiceid = t.transactionid
	join org.persons p on p.personID=t.bookkeeperid
	join cmn.currencies cr on cr.currencyID = i.currencyid
	join acc.articles a on a.articleid=t.articleid
	join org.contractors c on c.contractorID=t.clientid
	join org.contractors c2 on c2.contractorID = i.vendorid
	
go

select * from acc.invoices
select * from acc.invoices_v