if OBJECT_ID('fsc.CorrectionsData_v') is not null drop view fsc.CorrectionsData_v
go 
create view fsc.CorrectionsData_v as

select 
	id						=		rc.id
	, dateCorrected			=		rc.dateCorrected
	, name					=		ISNULL(p2.lfmname, p.lfmname) 
	, products				=		g.products
	, rc.saleid 
	, cash_payment			=		isnull(r.amount, 0) 
	, is_return				=		case t.transactiontypeID 
										when 12 then 'sale'
										when 13 then 'return'
									end 
	, reference_id  = s.receiptid
	, [year]				=		DATEPART(YYYY, t.transactiondate)
	, [month]				=		DATEPART(MM, t.transactiondate)
	, [day]					=		DATEPART(DD, t.transactiondate)
	, isnull(l.redirectTo, s.divisionID) divisionid
	, isnull( a.personid, p.personid) personid
	, t.transactiondate
from fsc.ReceiptCorrections rc
	join inv.sales s on s.saleID = rc.saleid
	join inv.transactions t on t.transactionID= s.saleID
	left join acc.CardRedirectLog l on l.transactionId=s.saleID
	left join fsc.attendance a on a.divisionID=s.divisionID 
		and a.att_date = cast (t.transactiondate as date)
	join org.persons p on p.personID= s.salepersonID
	left join org.persons p2 on p2.personID = a.personid
	cross apply ( 
		SELECT '''' +  STRING_AGG(CONCAT('''', sg.barcodeid, ''' ,''', it.inventorytyperus, ''',', sg.amount), ';') AS products
		from inv.sales_goods sg			
			join inv.barcodes b on b.barcodeID =sg.barcodeid
			join inv.styles st on st.styleid = b.styleID
			join inv.inventorytypes it on it.inventorytypeID = st.inventorytypeID
		where sg.saleID= s.saleID
	) as g
	outer apply (
		select  sr.amount
		from inv.sales_receipts sr 
		where 
			sr.saleID=s.saleID
			and sr.receipttypeID =1
		) r
where rc.dateCorrected is null
go
select 
	[name], products, saleid, cash_payment, is_return, reference_id, [year], [month], [day]
from fsc.CorrectionsData_v where divisionid = org.division_id('07 Уикенд') 
and dateCorrected  is null
order by saleid desc
	

select * from fsc.attendance
