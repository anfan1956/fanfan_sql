use fanfan
go
--select * from hr.salary_dates where success is null; select * from hr.salary_jobs_log order by 2 desc
--select * from acc.transactions t where articleid = 13
if OBJECT_ID('rep.payroll_report_v') is not null drop view rep.payroll_report_v
go
create view rep.payroll_report_v as
with s (personid, сотрудник, дата, статья, документ, комментарий, сумма, контрагент, registerid) as (
select 
	e.personid,
	p.lfmname,
	cast(t.transdate as datetime) transdate,
	a.article,
	t.document,
	t.comment,
	t.amount* (1- 2 * e2.is_credit),
	c.contractor, 
	e2.registerid
from acc.entries e
	join acc.entries e2 on e2.transactionid = e.transactionid and e2.is_credit<>e.is_credit
	join acc.transactions t on t.transactionid=e.transactionid
	join acc.articles a on a.articleid=t.articleid
	join org.persons p on p.personID = e.personid
	left join org.contractors c on c.contractorID=e.contractorid
where e.accountid = acc.account_id( 'зарплата к оплате')
)
select * from s
go

select * 
from rep.payroll_report_v
select * 
from hr.salary_BegEntries
