
if OBJECT_ID('acc.divisions_cash_f') is not null drop function acc.divisions_cash_f
go 

create function acc.divisions_cash_f (@date date) returns table as return
with _sales (transid, transdate, amount, account, transtype, personid) as (
	select 
		s.saleID,
		cast(t.transactiondate as date),
		sum (sr.amount * iif(tt.transactiontypeID = 13, -1, 1)),
		replace('hc' + d.divisionfullname, ' ', ''), 
		tt.transactiontype, 
--		rt.receipttype,
		s.salepersonID
	from inv.sales_receipts sr
		join inv.transactions t on t.transactionID= sr.saleID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join inv.sales s on s.saleID=sr.saleID
		join org.divisions d on d.divisionID= s.divisionID
		join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
	where rt.receipttype like '%cash%'
		and cast(t.transactiondate as date)>='20220101'
	group by 
		s.saleID,
		d.divisionfullname, 
		cast(t.transactiondate as date), 
		tt.transactiontype, 
--		rt.receipttype, 
		s.salepersonID
)
, _final (transid, transdate, amount, registerid, shop, transtype, personid) as (
	select	
		s.transid,
		cast (s.transdate as datetime) transdate,
		s.amount, 
		r.registerid, 
		acc.shop_f(r.registerid) shop, 
		s.transtype,
		s.personid
	from _sales s
		join acc.registers r on r.account= s.account
		join acc.beg_entries_around_date_f(@date) f 
			on f.registerid= r.registerid and s.transdate >=f.entrydate

	union all 
	select
		f.entryid,
		f.entrydate, 
		f.amount, 
		f.registerid,
		acc.shop_f(v.registerid), 
		'пересчет', 
		f.bookkeperid
	from acc.beg_entries_around_date_f (@date) f
		join acc.registers_hc_v v on v.registerid=f.registerid

	union all 
	select 
		t.transactionid,
		t.transdate, 
		t.amount * (1 - 2 * e.is_credit ), 
		e.registerid, 
		acc.shop_f(e.registerid), 
		a.article, 
		cor.personid
	from acc.transactions t
		join acc.entries e on e.transactionid = t.transactionid
		join acc.entries cor on cor.transactionid =e.transactionid and cor.is_credit<>e.is_credit
		join acc.registers_hc_v v on v.registerid=e.registerid
		join acc.articles a on a.articleid=t.articleid
		join acc.beg_entries_around_date_f(@date) f 
			on f.registerid= e.registerid and t.transdate >=f.entrydate
)
select f.*, p.lfmname person
from _final f
	join org.persons p on p.personID = f.personid
go

declare @date date = '20221201';
/*
select 
	t.transactionid, t.transdate, t.amount, t.clientid,  a.article,
	e.contractorid, e.is_credit, e.personid, e.registerid
from acc.transactions t 
	join acc.articles a on a.articleid=t.articleid
	join acc.entries e on e.transactionid = t.transactionid
where t.transactionid > 1159
*/

--declare @note varchar(max), @paymentid int = 1160; exec acc.payment_delete_p @note output,	@paymentid; select @note;
select * from acc.divisions_cash_f('20221201')

select * from acc.beg_entries