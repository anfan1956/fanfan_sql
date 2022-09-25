USE [fanfan]
GO

ALTER view  [fin].[cash_register_flow_verified_v] as 

--- hardcoding temporarily first part of _source
with _journals (journal) as (select 'cash' union all select 'hard cash')
,  _startdates (topdate, journal, journalid, divisionid, divisionid_ff) as
	(select cast ('20210101'as date) topdate, j.journal, anfan_release.acc.journalid_func(j.journal), d.divisionid, d.divisionid_ff
	from anfan_release.org.divisions d
		cross apply _journals j
	where d.retail='true')

	-- find the top dates from the begining entries from anfan_release database
, _topdates (topdate, journal, journalid, divisionid, divisionid_ff) as
		(	select isnull(b.be_date, s.topdate), s.journal, s.journalid, s.divisionid, s.divisionid_ff
			From _startdates s
			left join  anfan_release.acc.be_top_v b on b.journalid=s.journalid and b.divisionid=s.divisionid
		)
, _transsign (saleid, opersign) as
(
	select sg.saleID, 
		case t.transactiontypeid when inv.transactiontype_id('RETURN') then -1
		else 1 end		
	from inv.sales sg
		join inv.transactions t on t.transactionID=sg.saleID
)

	-- find sales  and returns from  inv.sales_receipts
, _source (id, сумма, дата, divisionid, статья, сотрудник, [кнтр/агент], операция, учет)  as 
(
	select 
		sr.saleID id, sum(sr.amount)* sg.opersign
		, t.transactiondate, s.divisionID, 
		case when sr.receipttypeID = 1 then 'продажи 1С' 
			when sr.receipttypeID in (3, 6) then 'продажи' end статья, 		
		c.lfmname, 
		p.lfmname, 
		'продажа/возврат'
		, case sr.receipttypeID
			when inv.receipttype_id('hard cash') then 'упр.'
			when inv.receipttype_id('hard cash to rep') then 'упр.'
			when inv.receipttype_id('cash') then '1С'
		end
	from inv.sales_receipts sr
		join _transsign sg on sg.saleid=sr.saleid
		join inv.transactions t on t.transactionID=sr.saleID
		join inv.sales s on s.saleID=sr.saleID
		join org.persons c on c.personID = s.salepersonID 
		join cust.persons p on p.personID=s.customerID
		join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
		join _topdates td on td.journal = 
			case rt.receipttype when 'hard cash to rep' then 'hard cash'
			else rt.receipttype end
		and td.divisionid_ff=s.divisionID
		and t.transactiondate>=td.topdate
	where sr.receipttypeID in (1, 3, 6)
	group by sr.saleID, t.transactiondate, s.divisionID, sr.receipttypeID, p.personID, c.lfmname, p.lfmname , sg.opersign
			union 
			select f.transactionid, g.amount * (1-2*w.is_draw), f.transactiondate, 
				d.divisionid_ff divisionid, 
				case w.journalid when 3 then 'касса 1С' when 5 then 'касса' end cf_part, c.contractor, ct.contractor, 
				'прием/выдача' 
				, case w.journalid when 3 then '1С' when 5 then 'упр.' end
			from anfan_release.acc.cash_withdrawals w
				join anfan_release.acc.generalledger g on g.transactionid=w.drawid
				join anfan_release.org.contractors ct on ct.contractorid=g.contractorid
				join anfan_release.acc.fin_transactions f on f.transactionid=w.drawid
				join anfan_release.org.divisions d on d.divisionid=f.divisionid
				join anfan_release.org.contractors c on c.contractorid=w.operatorid
				join _topdates td on td.journalid=w.journalid 
					and td.divisionid_ff=d.divisionid_ff and f.transactiondate>=td.topdate
			where g.contractorid is not null
			union all 
			select  0, amount, be.be_date, d.divisionid_ff, 
			case be.journalid when 3 then 'касса 1С' when 5 then 'касса' end cf_part 
				, c.contractor, ct.contractor, 'пересчет'

				, case be.journalid when 3 then '1С' when 5 then 'упр.' end
			from anfan_release.acc.be_top_v be 
				join anfan_release.org.divisions d on d.divisionid=be.divisionid
				JOIN anfan_release.org.contractors c on c.contractorID=be.authorityid
				left join anfan_release.org.contractors ct on ct.contractorID=be.contractorid
		)
select 
	s.id, s.сумма,  dbo.justdate( s.дата) as   [дата], d.divisionfullname магазин, 
	s.сотрудник, s.[кнтр/агент], s.статья, s.операция, s.учет, 
	DATEPART(M,s.дата) месяц, DATEPART(YYYY,s.дата) год, DATEPART(WK,s.дата) неделя, FORMAT(s.дата, 'HH:mm') время
from _source s
	join org.divisions d on d.divisionID=s.divisionID
GO


