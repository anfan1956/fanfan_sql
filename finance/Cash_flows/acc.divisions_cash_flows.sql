

if OBJECT_ID('acc.divisions_cash_f') is not null drop function acc.divisions_cash_f
go 

create function acc.divisions_cash_f (@date date) returns table as return
with _sales (transdate, amount, account, transtype) as (
	select 
		cast(t.transactiondate as date),
		sum (sr.amount * iif(tt.transactiontypeID = 13, -1, 1)),
		replace('hc' + d.divisionfullname, ' ', ''), 
		tt.transactiontype
	from inv.sales_receipts sr
		join inv.transactions t on t.transactionID= sr.saleID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join inv.sales s on s.saleID=sr.saleID
		join org.divisions d on d.divisionID= s.divisionID
		join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
	where receipttype like '%cash%'
		and cast(t.transactiondate as date)>='20220101'
	group by 
		d.divisionfullname, 
		cast(t.transactiondate as date), 
		tt.transactiontype
)
select	
	cast (s.transdate as datetime) transdate,
	s.amount, 
	r.registerid, 
	acc.shop_f(r.registerid) shop, 
	s.transtype
from _sales s
	join acc.registers r on r.account= s.account
	join acc.beg_entries_around_date_f(@date) f 
		on f.registerid= r.registerid and s.transdate >=f.entrydate
union all 
select 
	f.entrydate, 
	f.amount, 
	f.registerid,
	acc.shop_f(v.registerid), 
	'пересчет'
from acc.beg_entries_around_date_f (@date) f
	join acc.registers_hc_v v on v.registerid=f.registerid


go


declare @date date = '20221201';
