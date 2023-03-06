use fanfan
go

if OBJECT_ID('acc.divisions_cash_f') is not null drop function acc.divisions_cash_f
go 

create function acc.divisions_cash_f (@date date) returns table as return
with _final (transid, transdate, amount, registerid, shop, transtype, personid, comment) as (
	select 
		s.saleID,
		cast(t.transactiondate as date),
		sum (sr.amount * iif(tt.transactiontypeID = 13, -1, 1)),
		r.registerid,
		d.divisionfullname,
		tt.transactiontype, 
		s.salepersonID,
		rt.r_type_rus
	from inv.sales_receipts sr
		join inv.transactions t on t.transactionID= sr.saleID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join inv.sales s on s.saleID=sr.saleID
		join org.divisions d on d.divisionID= s.divisionID
		join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
		join acc.registers r on r.account= replace('hc' + d.divisionfullname, ' ', '') 
		join acc.beg_entries_around_date_f(@date) f 
			on f.registerid= r.registerid and cast(t.transactiondate as date) >=f.entrydate
	where rt.r_type_rus	 in ( 'наличные', 'перевод в банк')
	group by 
		s.saleID,
		d.divisionfullname, 
		cast(t.transactiondate as date), 
		tt.transactiontype,
		r.registerid, 	 
		s.salepersonID, 
		rt.r_type_rus
	union all 
	select
		f.entryid,
		f.entrydate, 
		f.amount, 
		f.registerid,
		acc.shop_f(v.registerid), 
		'пересчет', 
		f.bookkeeperid, 
		'нач. остатки'
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
		cor.personid, 
		t.comment
	from acc.transactions t
		join acc.entries e on e.transactionid = t.transactionid
		join acc.entries cor on cor.transactionid =e.transactionid and cor.is_credit<>e.is_credit
		join acc.registers_hc_v v on v.registerid=e.registerid
		join acc.articles a on a.articleid=t.articleid
		join acc.beg_entries_around_date_f(@date) f 
			on f.registerid= e.registerid and t.transdate >=f.entrydate
)
select 
	f.transid, 
	cast(transdate as datetime) transdate, 
	amount,
	registerid, 
	shop,
	transtype, 
	f.personid, 
	p.lfmname person, 
	f.comment
from _final f
	left join org.persons p on p.personID = f.personid
go

declare @date date = getdate()
--declare @note varchar(max), @paymentid int = 1160; exec acc.payment_delete_p @note output,	@paymentid; select @note;
select * from acc.divisions_cash_f(@date)
select * from acc.beg_entries_around_date_f(@date)
