declare @date date ='20230130', @number int =1;
declare @scope varchar(10) ;
select @scope = 'quater'; 

--version 03.07.2023
if OBJECT_ID('acc.sales_rollout_f1') is not null drop function acc.sales_rollout_f1 
go
create function acc.sales_rollout_f1(@date date, @scope varchar(10), @number int) returns table as return

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
, 
 _cash_registers (registerid) as (
	select registerid from acc.registers r 
	where r.bankid=r.clientid 
	or r.clientid = org.contractor_id('федоров а. н.')
)
, _f_charges (accountid, chargeAccId, is_debet) as (
	select acc.account_id('деньги, банк'), acc.account_id('деньги, банк'), null
	union select  acc.account_id('деньги, банк'), acc.account_id('деньги, банк'), 0 
	union select  acc.account_id('деньги, банк'), acc.account_id('фин. расходы'),  1
)
, _acq(datestart, registerid, rate, days_off, acqTypeid, contractorid, num) as (
	select 
		a.datestart, a.registerid, a.rate, days_off, a.acqTypeid, r.bankid, 
		ROW_NUMBER() over(partition by a.registerid, a.acqTypeid, r.bankid order by a.datestart desc)
	from acc.acquiring a
		join acc.registers r on r.registerid = a.registerid
)
, _seed (accountid, factor, daysShift) as (
		select null, 1, null
		union select acc.account_id('эквайринг'), -1, null	
		union select a.accountid, 
			case a.accountid
				when acc.account_id('выручка') then -1
				when acc.account_id('себестоимость') then 0.4
				when acc.account_id('товар') then -0.4
				when acc.account_id('эквайринг') then 1
				end, 
			0
		from acc.accounts a
		where a.account in ('выручка', 'себестоимость', 'товар', 'эквайринг')
		)
, _sales (saleid, transtypeid, divisionid, transDate, accountid, amount, daysShift, account, registerid, receipttypeid, acqTypeid) as (
	select 
		sr.saleID, 
		t.transactiontypeID,
		s.divisionID,	
		cast(t.transactiondate as date),
		isnull (se.accountid, ra.accountid) accountid, 
		sr.amount * se.factor * iif(tt.transactiontype = 'Return', -1,1)  amount, 
		case 
			when sr.registerid in (select registerid from _cash_registers) then 0 
			else se.daysShift end daysShift, 
		a.account, 
		sr.registerid, 
		sr.receipttypeID, 
		rt.acqTypeid
	from inv.sales_receipts sr 	
		join inv.sales s on s.saleID=sr.saleID
		join acc.registers_accounts ra on ra.registerid = sr.registerid	
		join acc.rectypes_acqTypes rt on rt.receipttypeID=sr.receipttypeID
		cross apply _seed se	
		left join acc.accounts a on a.accountid = isnull(se.accountid, ra.accountid)
		join inv.transactions t on t.transactionID=sr.saleID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
			cross apply _day_scope od
			cross apply _month_scope d
			cross apply _quater_scope qd
			cross apply _year_scope yd	
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
)
, _final_numbered (saleid, transtypeid, transDate, accountid, amount, daysShift, datestart, registerid, receipttypeid, is_debet, chargeAccId, contractorid) as (
	select
		s.saleid, 
		s.transtypeid, 
		s.transDate, 
		isnull(chargeAccId, s.accountid) accountid, 
		s.amount * (2 * isnull(is_debet, 1) -1) * 
			case 
				when is_debet is null then 1 
					else iif(s.transtypeid= 13, 0, a.rate) end 
		amount, 
		isnull(s.daysShift, a.days_off) daysShift, 
		a.datestart, s.registerid, s.receipttypeid, 
		f.is_debet, f.chargeAccId, 
		case 
			when isnull(chargeAccId, s.accountid) in (acc.account_id('эквайринг'), acc.account_id('фин. расходы')) then a.contractorid
			else null end 
	from  _sales s
		left join _acq a 
			on a.registerid =s.registerid  
			and a.acqTypeid=s.acqTypeid
			and a.datestart<=s.transDate
			and a.num=1
		left join _f_charges f on f.accountid=s.accountid

), 
_final (saleid, transtypeid, transDate, accountid, account, amount, registerid, is_debet, accPart, contractorid, num) as (
	select 
		f.saleid, 
		f.transtypeid, 
		DATEADD(dd,daysShift, f.transDate) transDate, 
		f.accountid, 
		a.account,
		f.amount, 
		f.registerid, 
		f.is_debet, 
		p.accPart, 
		f.contractorid, 
		iif(f.accountid=22, ROW_NUMBER() over (
			partition by 
				saleid, transdate, daysShift, f.accountid, registerid, receipttypeid 
			order by datestart desc), 1) num
	from _final_numbered f
		join acc.accounts a on a.accountid=f.accountid	
		join acc.acchart_parts p on a.accPartid=p.partid
)
select 	
	f.saleid, 
	f.transDate, 
	tt.transactiontype, 
	f.accountid, 
	f.account, 
	f.amount, 
	f.accPart, 
	acc.article_id('Розничная выручка') articleid, 
	f.registerid, 
	f.contractorid, 
	ROW_NUMBER() over (partition by saleid, transdate, accountid order by is_debet) num
from _final f
			join inv.transactiontypes tt on tt.transactiontypeID= f.transtypeid
where iif(accountid = acc.account_id('деньги, банк'), num, 1) = 1


go

declare @date date ='20230130';
declare @scope varchar(10), @number int =2;
select @scope = 'quater'; 
select s.* from acc.sales_rollout_f1(@date, @scope, @number) s




