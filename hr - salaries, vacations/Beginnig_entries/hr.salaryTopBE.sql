if OBJECT_ID('hr.salaryTopBE_date_f') is not null drop function hr.salaryTopBE_date_f
go 
create function hr.salaryTopBE_date_f (@date date) returns table as return
with 
 s (personid, entrydate, document, clientid, amount, num) as (
	select employeeid, entrydate, 
		case t.salarytype
			when 'касса' then 'cash'
			when 'банк' then 'bank' end, 
		clientid, 
		amount,
		ROW_NUMBER() over (partition by s.employeeid, s.salarytypeid, clientid order by s.entrydate desc) 
	from hr.salary_BegEntries s
		join hr.salarytypes t on t.salarytypeID=s.salarytypeid
	where s.entrydate<=@date
	)
	select 
		s.personid,
		cast(s.entrydate as datetime) entrydate, 

		acc.article_id('ЗАРПЛАТА - НАЧ. ОСТАТКИ') articleid,
		s.document, 
		'начальные остатки' comment, 
		s.clientid, 
		amount, 
		null registerid
	from s where num =1 
go
declare @date date = cast (getdate() as date)
select * from hr.salaryTopBE_date_f(@date) where personid = 1075

if OBJECT_ID('rep.salaryReport_BEdate_f') is not null drop function rep.salaryReport_BEdate_f
go
create function rep.salaryReport_BEdate_f(@date date) returns table as return
with 
active as (
	select distinct s.personid
	from hr.schedule_21 s
	join org.persons p on p.personID=s.personid
	where s.date_finish is null or DATEDIFF(mm, s.date_finish, GETDATE())< 2
	)
,
s as (select 
	e.personid,
	cast(t.transdate as datetime) transdate,
	t.articleid,
	t.document,
	t.comment,
	t.clientid, 
	t.amount* (1- 2 * e2.is_credit) amount,
	e2.registerid
from acc.entries e
	join acc.entries e2 on e2.transactionid = e.transactionid and e2.is_credit<>e.is_credit
	join acc.transactions t on t.transactionid=e.transactionid
--	join hr.salaryTopBE_date_f (@date) s on 
	join (select distinct personid, entrydate, articleid, document, comment, amount from hr.salaryTopBE_date_f(@date)) s on 
		s.personid=e.personid and
		s.document=t.document and
		t.transdate>=s.entrydate

where e.accountid = acc.account_id( 'зарплата к оплате')
union all 
select * from hr.salaryTopBE_date_f(@date) 
)
, _united (personid, сотрудник, дата, статья, комментарий, документ, сумма, reg_id, банк, счет_банк) as (
select 
	s.personid, p.lfmname, transdate, article, comment, s.document, amount, 
	isnull(s.registerid, 0), isnull(c.contractor, '') bank, isnull( r.account, '')
from s
	join acc.articles a on a.articleid=s.articleid
	join org.persons p on p.personID = s.personid
	left join acc.registers r on r.registerid = s.registerid
	left join org.contractors c on c.contractorID= r.bankid
)
select 
	distinct
	--u. * ,
	u.personid, 
	u.сотрудник, 
	дата, 
	datepart (YYYY, u.дата) год,
	datepart (MM, u.дата) месяц,
	статья, 
	комментарий, 
	trim(документ) документ, 
	сумма, reg_id, банк, счет_банк
from _united u
join active s on s.personid =u.personid
go


declare @date date = '20231201';
select * from rep.salaryReport_BEdate_f(@date) s
where s.personid =1073
