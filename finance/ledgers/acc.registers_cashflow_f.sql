if OBJECT_ID('acc.registers_cashflow_f')  is not null drop function acc.registers_cashflow_f
go

create function acc.registers_cashflow_f (@date date) returns table as return



	with _s as (
		select 
			--hardcoding 'returns' (transactiontypeid =13
			t.transactionID,
			sr.amount  * iif(t.transactiontypeID=13, -1, 1) amount,
			s.divisionID, 
			d.divisionfullname shop,
			a.registerid, 
			t.transactiondate, 
			tt.transactiontype,
			a.com_rate, 
			s.salepersonID, 
			ROW_NUMBER() over (partition by a.registerid, t.transactionid order by a.datestart desc) num
		from inv.sales_receipts sr
			join inv.transactions t on t.transactionID= sr.saleID
			join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
			join inv.sales s on s.saleID=sr.saleID
			join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
			join org.divisions d on d.divisionID=s.divisionID
			join acc.registers r on r.clientid=d.clientID
			join acc.acquiring a on a.registerid=r.registerid and t.transactiondate>=a.datestart and a.datefinish is null
		where rt.r_type_rus = 'карта' 
		)
		, _fintype (ftype) as (
			select 'sale' union select 'commission'
		)
		, _with_commissions(transactionid, transdate, accountid, articleid, amount, registerid, comment, personid ) as (
			select 
				s.transactionid,
				cast(s.transactiondate as date) transdate, 
				case f.ftype 
					when 'sale'  then acc.account_id('выручка')
					else acc.account_id('эквайринг') end,
					acc.article_id('РОЗНИЧНАЯ ВЫРУЧКА'),
				case when 
						f.ftype = 'sale' then s.amount			
						when f.ftype = 'commission' and s.transactiontype <> 'return' then s.amount * - s.com_rate
				end amount, 
				s.registerid, 
				s.shop,
				s.salepersonID
			from _s s 
				join org.persons p on p.personID = s.salepersonID
				cross apply _fintype f
			where s.num=1 
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
			w.registerid, w.transactionid, w.transdate, w.amount, w.accountid, w.articleid, w.comment, w.personid
		from _with_commissions w 
		join acc.beg_entries_around_date_f(@date) d on d.registerid=w.registerid and w.transdate>=d.entrydate and d.num = 1
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
select * from acc.registers_cashflow_f(@date) f where f.registerid in  (8, 17)
order by 3;
go
