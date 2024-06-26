USE [fanfan]
GO
if OBJECT_ID('acc.balance_trial_f') is not null drop function acc.balance_trial_f
go 
create function acc.balance_trial_f(@date date, @scope varchar(10), @number int) returns table as return
	with 
	_day_scope (datestart, dateend) as (
		select dateadd(DD, @number -1, @date), @date
	)
	, _month_scope (datestart, dateend) as (
		select dateadd(DD, 1, EOMONTH(@date, -@number)), EOMONTH(@date, 0)
	)
	, _quater_scope (datestart,dateend) as (
		select 
			dateadd(DD, 1, eomonth(@date,-((month(@date)-1)%3 + ((@number-1) *3)+1) )) datestart, 
			eomonth(DATEADD(QQ, 1,  eomonth(@date,-(month(@date)-1)%3-1)), 0) datefinish
		)
	, _year_scope (datestart, dateend) as (
		select DATEFROMPARTS(YEAR(@date)-@number + 1, 1,1) , EOMONTH(@date, 0)
	)
	, _t (transid, transdate, amount, registerid, accountid, articleid, contractorid, party) as (
	select 
		t.transactionid,
		isnull (i.periodDate,t.transdate),
		t.amount * r.rate * (1 - 2 * e.is_credit) amount, 
		e.registerid, 		
		e.accountid, 
		t.articleid, 
		isnull (c.contractorID, isnull(e.contractorid, e.personid)),
		iif(c.contractorID is null, iif(e.contractorid is null, 'person', 'contractor'), 'contractor') party
	from acc.transactions t 
		join acc.entries e on t.transactionid = e.transactionid
		join cmn.currentrates r on r.currencyID= t.currencyid
		left join acc.registers re on re.registerid = e.registerid
		left join org.contractors c on c.contractorID= re.bankid
-- this is necessary to establid the period for charged expence
		left join acc.invoices i on i.invoiceid= t.transactionid
			cross apply _day_scope od
			cross apply _month_scope d
			cross apply _quater_scope q
			cross apply _year_scope yd	
		where cast(isnull (i.periodDate,t.transdate) as date) between 
			case @scope 
				when 'day' then od.datestart
				when 'month' then d.datestart 
				when 'quater' then q.datestart 
				when 'year' then yd.datestart end
			and 
				case @scope 
				when 'day' then od.dateend
				when 'month' then d.dateend
				when 'quater' then q.dateend 
				when 'year' then yd.dateend end	
		)
, _united (transid, transdate, amount, registerid, accountid, articleid, contractorid, party) as (
		select 		 
			t.transid, t.transdate, t.amount, t.registerid, t.accountid, t.articleid, t.contractorid, t.party
		from _t t
	union all 
		select 
			f.saleid, f.transdate, f.amount, f.registerid, f.accountid, f.articleid, f.contractorid, 'some party'
		from acc.sales_rollout_f1(@date, @scope, @number) f
)
select 
	u.registerid,
	u.transid, 
	u.transdate, 
	u.amount amount, 
	u.accountid, 
		case party when 'person' then p.lfmname
		else c.contractor end contractor, 
	ar.article,
	a.account, 
	ap.accPart part,
	g.group_name, 
	s.section, 
	rs.section секция, 
	ra.accountid [№ счета], ra.account счет, 
	r.subaccount субсчет,
	MONTH(u.transdate) [month], 
	Year (u.transdate) [year], 
	DAY(u.transdate) [day]
from _united u
	join acc.accounts a on a.accountid=u.accountid
	join acc.acchart_parts ap on ap.partid=a.accPartid
	join acc.groups g on  g.groupid= a.groupid
	join acc.sections s on s.groupid=a.groupid
	join acc.articles ar on ar.articleid= u.articleid
	left join org.contractors c on c.contractorID=u.contractorid 
	left join org.persons p on p.personID=u.contractorid 
	join RSBU_subaccounts r on r.subaccountid=a.rsbuSubId
	join RSBU_accounts ra on ra.accountid=r.accountid
	join RSBU_sections rs on rs.sectionid=ra.sectionid



go 
declare @date date = '20231130', @scope varchar(20) = 'quater', @num int =2
select * from acc.balance_trial_f(@date, @scope, @num) f 
where transid =79876
order by 2 desc


--select * from acc.transactions t 	join acc.entries e on e.transactionid= t.transactionid where t.transactionid = 1477
select * from acc.sales_rollout_f1(@date, @scope, 1)
where saleid= 79876