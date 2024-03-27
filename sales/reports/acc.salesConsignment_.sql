declare @date date = '20240101';
if OBJECT_ID('acc.salesConsignment_') is not null drop function acc.salesConsignment_
go 
create function acc.salesConsignment_(@date as date) returns table as return
with s (
	saleid, transactiontypeid, receipttypeID, r_type_rus, 
	aqrate, barcodeID, amount, cost, allComm, num) as 
	(
	select 
		sg.saleID, 
		tr.transactiontypeID, 		
		sr.receipttypeID, rt.r_type_rus, 
		a.rate aqrate,
		sg.barcodeID, 
		sg.amount * iif(tr.transactiontypeID=13, -1, 1) amount,
		st.cost
		, r.rate 
		+  case 
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
			, ROW_NUMBER() over (partition by sg.barcodeid, s.saleid, a.registerid, a.acqTypeid order by a.datestart desc) num

	from inv.sales s 
		join inv.sales_goods sg on sg.saleID=s.saleID
		join inv.transactions tr on tr.transactionID= s.saleID
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
		and tr.transactiondate>=@date	
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
	where s.num =1
)
select f.* from _final f
--select * from s;
go

declare @date date = '20240101'
select * from acc.salesConsignment_(@date) s where s.saleid= 81311
select * from inv.sales_receipts s where s.saleID= 81311

