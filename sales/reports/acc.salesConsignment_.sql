if OBJECT_ID('acc.salesConsignment_') is not null drop function acc.salesConsignment_
go 
create function acc.salesConsignment_(@date as date) returns table as return
with s as (
	select 
		sg.saleID, 		
		sr.receipttypeID, rt.r_type_rus, a.rate aqrate,
		sg.barcodeID, sg.amount, st.cost, r.rate + 
		case 
			--ставка аренды
			when s.fiscal_id is null then 0
			else .13*1.2  end  + 
		case 
			--ставка эквайринга
			when s.fiscal_id is null then 0
			else a.rate  end  +
		case 
			--ставка налога с оборота УСН
			when s.fiscal_id is null then 0
			else .06  end allComm 		
	from inv.sales s 
		join inv.sales_goods sg on sg.saleID=s.saleID
		join inv.sales_receipts sr on sr.saleID=s.saleID
		join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
		join inv.barcodes b on b.barcodeID=sg.barcodeID
		join inv.styles st on st.styleID = b.styleID
		join inv.transactions t on t.transactionID=st.orderID
		join hr.latest_comm_rates_date_f(@date) r on r.receipttypeid= sr.receipttypeID
		join acc.rectypes_acqTypes ra on ra.receipttypeid=sr.receipttypeID
		join acc.acquiring a on a.acqTypeid= ra.acqTypeid 
			and a.registerid = sr.registerid 
			and a.datestart<=t.transactiondate
	where t.transactiontypeID=inv.transactiontype_id('consignment')
		and t.transactiondate>=@date
)
, _final (saleid, barcodeid, форма_опл, выручка, комиссии, себ_ст, прибыль, доля_пр, к_выплате  ) as (
	select 
		s.saleID, 
		s.barcodeID, 
		s.r_type_rus, 
		amount, amount*allComm, cost, 
		amount - amount*allComm - cost profit, 
		(amount - amount*allComm - cost) * .6 profit_share,
		(amount - amount*allComm - cost) * .6 + cost totalPay
	from s
)
select f.* from _final f
go

declare @date date = '20240101'
select * from acc.salesConsignment_(@date)


select t.transactionid, t.transdate, t.recorded, a.article, t.amount, t.comment, t.document, t.saleid, 
	e.entryid, e.is_credit, ac.account, c.contractor 
from acc.transactions t
	join acc.entries e on e.transactionid=t.transactionid
	join acc.articles a on a.articleid=t.articleid
	join acc.accounts ac on ac.accountid=e.accountid
	join org.contractors c on c.contractorID=e.contractorid

where t.transactionid>=7840



select * from acc.salesConsignment_('20240101') where saleid = 81073;

