declare @date date = '20221230';
declare @scope varchar(10) 
select @scope = 'month'; 
--select @scope = 'day';
select @scope = 'year';

if OBJECT_ID('acc.sales_rollout_f') is not null drop function acc.sales_rollout_f
go
create function acc.sales_rollout_f(@date date, @scope varchar(10), @number int) returns table as return

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
	, _seed (accountid, is_credit, daysshift, markup) as (
		select 
			a.accountid, 
			case  when a.account in ('выручка', 'товар') then 1
				else 0 end, 
			case  when a.account in ('выручка', 'товар') then 1
				else null end, 
			case  when a.account in ('выручка', 'деньги') then 1
				else 0.4 end 
		from acc.accounts a
		where a.account in ('выручка', 'деньги', 'себестоимость', 'товар')
		), 
	_tb (saleid, salesdate, amount, clientid, bankid, accountid, typeid, registerid, datestart, days_off, rate)  as (
		select 
			sr.saleID, 
			cast(t.transactiondate as date),
			sum(
				sr.amount * 
				iif(t.transactiontypeID= 13, -1, 1) * 
				(1- 2 * is_credit) * a.markup
			), 
			dv.clientid, 
			c.contractorID,
			a.accountid, 
			ac.acqTypeid,	
			ac.registerid, 
			ac.datestart, 
			case accountid 
				when acc.account_id('деньги') then ac.days_off
				else 0 end,
			case accountid 
				when acc.account_id('деньги') then ac.rate
				else 0 end
		from inv.transactions t 
			join inv.sales_receipts sr on sr.saleID=t.transactionID
			join inv.sales s on s.saleID=t.transactionID
			join org.divisions dv on dv.divisionID=s.divisionID
			join acc.registers r on r.registerid =sr.registerid
			join org.contractors c on c.contractorID=r.bankid
			join acc.rectypes_acqTypes ra on ra.receipttypeid=sr.receipttypeID
			join acc.acquiring ac 
				on ac.registerid = sr.registerid 
				and ac.acqTypeid = ra.acqTypeid
				and ac.datestart<=cast(transactiondate as date)
			cross apply _day_scope od
			cross apply _month_scope d
			cross apply _quater_scope qd
			cross apply _year_scope yd	
			cross apply _seed a
		where cast(t.transactiondate as date) between 
			case @scope 
				when 'day' then od.datestart
				when 'month' then d.datestart 
				when 'quater' then qd.datestart 
				when 'year' then yd.datestart end
			and 
				case @scope 
				when 'day' then od.dateend
				when 'month' then d.dateend
				when 'quater' then qd.dateend
				when 'year' then yd.dateend end
		group by 
			a.accountid, 
			cast (t.transactiondate as date),
			ac.registerid, 
			ac.acqTypeid, 
			ac.datestart, 
			ac.days_off,
			sr.saleID, 
			dv.clientID, 
			c.contractorID, 
			ac.rate
		)
	, _numbered (saleid, salesdate, amount, clientid, bankid, accountid, typeid, registerid, datestart, days_off,num, rate) as (
		select 
			t.saleid,
			t.salesdate, 
			t.amount, 
			t.clientid, 
			t.bankid, 
			t.accountid, t.typeid, t.registerid, datestart, days_off,
			ROW_NUMBER () over ( partition by t.saleid, t.salesdate, t.accountid, t.registerid, t.typeid order by t.datestart desc), 
			t.rate
		from _tb t 
		)
	, _acquiring_seed (acq_accountid, days_shift, is_credit, rate ) as (
		select  acc.account_id('эквайринг'), 0, 0, 1
		union all 
		select acc.account_id('эквайринг') , 1, 1, 1
		union all 
		select acc.account_id('деньги'), 1, 0, 1
		union all 
		select acc.account_id('фин. расходы'), 1, 0, null
		union all 
		select acc.account_id('деньги'), 1, 1, null
		)
	, _final (saleid, salesdate, typeid, registerid, days_off, transdate, amount, accountid, contractorid,  num) as (
		select 
			saleid, salesdate, 
			typeid, registerid, days_off, 
			isnull(DATEADD(dd, days_off * days_shift, salesdate), salesdate),
			isnull(amount * (1 - 2 * se.is_credit) *
			isnull(cast(se.rate as decimal(5, 4)),cast( n.rate as decimal(5,4)))
				, amount), 
			isnull(se.acq_accountid, n.accountid) accountid, 
			case 
				when se.acq_accountid is null then n.clientid
				else n.bankid end, 
			num
		from _numbered n 
			left join  _acquiring_seed se on n.accountid = acc.account_id('деньги')
		where n.num=1 
	)
	select 
		f.saleid, 
		transdate, 
		amount, 
		registerid, 
		f.accountid, 
		acc.article_id('РОЗНИЧНАЯ ВЫРУЧКА') articleid, 
		f.contractorid, 
		'contractor' party
	from _final f
go

declare @date date ='20230130';
declare @scope varchar(10) 
select @scope = 'quater'; 
select s.*
	--, a.account 
from acc.sales_rollout_f(@date, @scope, 1) s
--join acc.accounts a on a.accountid= s.accountid


