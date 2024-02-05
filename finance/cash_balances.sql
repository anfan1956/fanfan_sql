--draft for cash_balances

select * from acc.current_cash_v
;

with _b (entrydate, entryid, registerid, amount, num)  as (
	select 
		b.entrydate, b.entryid, b.registerid, b.amount, 
		ROW_NUMBER() over (partition by b.registerid order by b.entrydate desc)
	FROM acc.beg_entries b
), 
_bdate (be_date, registerid) as (select entrydate, registerid from _b where num=1)
, s as (
	select 		
		t.transdate, 
		t.transactionid, 
		e.registerid, 
		t.amount * (1-2 * is_credit) amount
	from acc.transactions t 
		join acc.entries e on e.transactionid =t.transactionid
	where e.registerid is not null
)
, t (saledate, saleid, amount, registerid, num) as (
select 
	cast(t.transactiondate as date) saledate,   
	sr.saleid, 
	sr.amount * case t.transactiontypeID 
		when inv.transactiontype_id('return') then -1
		else 1
		end amount, 
		sr.registerid,
		ROW_NUMBER() over (partition by sr.saleid, sr.receipttypeID order by a.datestart desc) num
from inv.sales_receipts sr
	join inv.transactions t on t.transactionID=sr.saleID		
	join acc.rectypes_acqTypes ra on ra.receipttypeID=sr.receipttypeID
		left join acc.acquiring a on a.acqTypeid=ra.acqTypeid and a.registerid=sr.registerid
where  
	cast(isnull(a.datestart, t.transactiondate) as date) <= cast( t.transactiondate as date) 
)
, _comb (transdate, transid, regid, amount, src) as (
select b.entrydate, b.entryid, b.registerid, b.amount, 'be'
from _b b
union all 
select 
	s.transdate, s.transactionid, s.registerid, s.amount, 'ledger'
from s
union all
select
	t.saledate, t.saleid, t.registerid, t.amount, 'sales'
from t
where t.num =1
)	
select
	 c.transdate, 
	 c.src,
	 c.regid, 
	c.amount , 
	sum (c.amount) over (order by c.transdate rows between unbounded preceding and current row)
from _comb c
	join  _bdate b on b.registerid=c.regid
where c.regid =7
	and c.transdate >=b.be_date
order by 1 