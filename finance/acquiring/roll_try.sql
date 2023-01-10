declare @date date = '20221231';
declare @scope varchar(10) 
select @scope = 'day';


--select  top 1 * from acc.balance_trial_f (@date);
with 
_day_scope (datestart, dateend) as (
	select dateadd(DD, 0, @date), dateadd(DD, 0, @date)
)
, _month_scope (datestart, dateend) as (
	select dateadd(DD, 1, EOMONTH(@date, -1)), EOMONTH(@date, 0)
--	select dateadd(DD, -1, EOMONTH(@date, 0)), EOMONTH(@date, 0)
)
, _year_scope (datestart, dateend) as (
	select DATEFROMPARTS(YEAR(@date), 1,1) , EOMONTH(@date, 0)
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
)
, _acquiring_seed (acq_accountid, days_shift, is_credit ) as (
	select acc.account_id('эквайринг'), 0, 0
	union all 
	select null, 1, 1
)
, _tb (salesdate, amount, accountid, acqTypeid, registerid, datestart, days_off)  as (
	select 
		
		cast(t.transactiondate as date),
		sum(
			sr.amount * iif(t.transactiontypeID= 13, -1, 1) 
			* (1- 2 * is_credit) * a.markup
			),
		a.accountid, 
		ac.acqTypeid,	
		ac.registerid, 
		ac.datestart, 
		ac.days_off
	from inv.transactions t 
		join inv.sales_receipts sr on sr.saleID=t.transactionID
		join acc.rectypes_acqTypes ra on ra.receipttypeid=sr.receipttypeID
		join acc.acquiring ac 
			on ac.registerid = sr.registerid 
			and ac.acqTypeid = ra.acqTypeid
			and ac.datestart<=cast(transactiondate as date)
		cross apply _day_scope od
		cross apply _month_scope d
		cross apply _year_scope yd	
		cross apply _seed a
	where cast(t.transactiondate as date) between 
		case @scope 
			when 'day' then od.datestart
			when 'month' then d.datestart 
			when 'year' then yd.datestart end
		and 
			case @scope 
			when 'day' then od.dateend
			when 'month' then d.dateend
			when 'year' then yd.dateend end
--where cast(t.transactiondate as date) between od.datestart and od.dateend

--	where cast(t.transactiondate as date) = @date
	group by 
		a.accountid, 
		cast (t.transactiondate as date),
		ac.registerid, 
		ac.acqTypeid, 
		ac.datestart, 
		ac.days_off		
), 
_numbered (salesdate, amount, accountid, acqTypeid, registerid, datestart, days_off, num) as (
select *, 
	ROW_NUMBER () over (partition by s.salesdate, s.accountid,  s.registerid, s.acqTypeid order by datestart desc) num
from _tb s 
)
select * from _numbered n where num =1

