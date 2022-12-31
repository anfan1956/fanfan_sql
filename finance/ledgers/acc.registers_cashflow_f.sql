declare @date date = getdate();
if OBJECT_ID('acc.registers_cashflow_f')  is not null drop function acc.registers_cashflow_f
go

create function acc.registers_cashflow_f (@date date) returns table as return

with 
_dates (registerid, entrydate) as (
	select registerid, entrydate
	from acc.beg_entries_around_date_f(@date)
)
, _s as (
	select 
		s.saleID, 
		s.divisionID, 
		s.customerID, 
		s.salepersonID, 
		sr.amount, 
		rd.registerid, 
		t.transactiondate, 
		t.transactiontypeID
	from inv.sales_receipts sr
		join inv.transactions t on t.transactionID = sr.saleID
		join inv.sales s on s.saleID=sr.saleID
		join fin.receipttypes rt on rt.receipttypeID= sr.receipttypeID
		join acc.registerid_divisionid_v rd on rd.divisionID=s.divisionID 
		join _dates dt on dt.registerid= rd.registerid and t.transactiondate>=dt.entrydate
	where rt.r_type_rus = 'наличные'
)
, _all_acq_registers (saleid, divisionid, customerid, salespersonid, amount, registerid, transactiondate, transtypeid, rate, num) as (
	select 
		s.saleID, 
		s.divisionID, 
		s.customerID, 
		s.salepersonID, 
		sr.amount, 
		rd.registerid, 	
		t.transactiondate, 
		t.transactiontypeID, 
		a.com_rate,
		ROW_NUMBER () over (partition by s.saleid order by a.datestart desc)		
	from inv.sales_receipts sr
		join inv.transactions t on t.transactionID = sr.saleID
		join inv.sales s on s.saleID=sr.saleID
		join fin.receipttypes rt on rt.receipttypeID= sr.receipttypeID
		join org.divisions d on d.divisionID=s.divisionID
		join acc.registers rd on rd.clientid = d.clientID
		join _dates dt on dt.registerid=rd.registerid and t.transactiondate>=dt.entrydate
		join acc.acquiring a on a.registerid=rd.registerid and a.datestart<=t.transactiondate
	where rt.r_type_rus = 'карта'
)
, _seed (accountid, factor, date_factor) as ( 
	select acc.account_id('выручка'), 1.0000, 0
	union all 
	select acc.account_id('эквайринг'), -1.0000, 0
	union all
	select acc.account_id('эквайринг'), 1.0000, 1
	union all
	select acc.account_id('фин. расходы'), null, 1
	)
, _united as (
	select 
		saleid, divisionid, customerid, salespersonid, 
		amount 	* isnull(s.factor, -a.rate) amount, 
		registerid, 
		DATEADD(DD, s.date_factor, transactiondate) transactiondate, 
		a.transtypeid,	
		s.accountid 
	from _all_acq_registers a
		cross apply _seed s
	where num = 1
	union all 
	select *, acc.account_id('выручка')
	from _s s
)
, _final as (
	select 
		u.saleid, 
		u.divisionid, 
		u.customerid, 
		u.salespersonid, 
		u.amount * iif(tt.transactiontypeID=13, -1, 1) amount , 
		registerid, transactiondate, transactiontype, u.accountid
	from _united u 
		join inv.transactiontypes tt on tt.transactiontypeID= u.transtypeid
)
, _ext_e as (
	-- extend entries to include fields from t.transactions
		select 
			e.*, t.transdate, t.amount, t.articleid, t.comment
		from acc.entries e
			join acc.transactions t on t.transactionid=e.transactionid
			join acc.entries e2 on e2.transactionid=e.transactionid and e2.is_credit <> e.is_credit
		where e.registerid is not null
	)
	, s (registerid, transactionid, transdate, amount, accountid, articleid, comment, personid) as (
		select 
			e.registerid, 
			e.transactionid, 
			e.transdate, 
			cast (e.amount * (1-2* e.is_credit) as money), 
			e2.accountid,
			e.articleid, 
			e.comment, 
			e2.personid
		from _ext_e e
			join acc.entries e2 on e2.transactionid=e.transactionid and e.is_credit<>e2.is_credit
			join acc.beg_entries_around_date_f(@date) d on d.registerid=e.registerid and e.transdate>=d.entrydate and d.num = 1
		union all 
		select 
			e.registerid, 
			e.entryid, 
			e.entrydate, 
			e.amount, 
			acc.account_id('деньги'), 
			a.articleid, 
			null, null
		from acc.beg_entries e 
			join acc.beg_entries_around_date_f(@date) d on d.entryid=e.entryid
			cross apply acc.articles a
		where 
			a.article = 'НАЧАЛЬНЫЕ ОСТАТКИ'
		union all
		select  
			registerid, 
			saleid, 
			cast (transactiondate as date) transactiondate, 
			f.amount, 
			f.accountid, 
			acc.article_id('РОЗНИЧНАЯ ВЫРУЧКА') articleid,
			divisionfullname, 
		--	customerid, 
--			transactiontype, 
			salespersonid 
		from _final f
			join org.divisions d on d.divisionID=f.divisionid
)
	select 
		s.registerid, 
		s.transactionid, 
		cast (s.transdate as datetime) дата, 
		s.amount сумма, 
		a.account план_счетов, 
		ar.article статья, 
		sum (s.amount) over (partition by s.registerid order by s.transdate, transactionid) reg_total, 
		c.contractor банк, 
		c2.contractor клиент,
		r.account счет_банк, 
		isnull(p.lfmname, '') получатель, 
		isnull(s.comment, '') комментарий
from s
		join acc.accounts a on a.accountid=s.accountid
		join acc.articles ar on ar.articleid=s.articleid
		join acc.registers r on s.registerid = r.registerid
		join org.contractors c on c.contractorID=r.bankid
		join org.contractors c2 on c2.contractorID = r.clientid
		left join org.persons p on p.personID = s.personid

go

--declare  @registerid int = 7
declare @date date = '20221201'; 
select * from acc.registers_cashflow_f(@date) f order by 3;

go
