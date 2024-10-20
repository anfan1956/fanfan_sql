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

