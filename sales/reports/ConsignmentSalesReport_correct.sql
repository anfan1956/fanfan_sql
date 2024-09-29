declare @date date = '20240101', @account varchar(max) ='счета к оплате', @contractor varchar(max)='E&N suppliers', @saleid int  = 84811

--this is previously calculated amount, wrong
select * from acc.consignmentReport_(@contractor, @account) r where [register/saleid]=cast(@saleid as varchar(max))

--this one is correct 
;with cte as (
select 
	sg.saleID, sg.barcodeID, sg.amount, b.cogs, st.orderID 
	, cmn.TurnoverTaxSimple(tr.transactiondate, default) taxRate
	, rr.rate renRate
	, aq.rate bankRate
	, com.rate comRate
	, (sg.amount) * (1- 
				cmn.TurnoverTaxSimple(tr.transactiondate, default) 
				-rr.rate -
				aq.rate - com.rate) - b.cogs netProfit
from inv.sales_goods sg
	join inv.sales_receipts sr on sr.saleID=sg.saleID
	join inv.sales s on s.saleID =sg.saleID
	join inv.barcodes b on b.barcodeID=sg.barcodeID
	join inv.styles st on st.styleID =b.styleID
	join inv.orders o on o.orderID = st.orderID and o.orderclassID = inv.orderclass_id('CONSIGNMENT')
	join inv.transactions tr on tr.transactionID=sg.saleID
	outer apply (
		select top 1 rr.rate * 1.2 -- НДC
		from acc.rentRate rr 
		where rr.divisionid=s.divisionID 
			and rr.dateStart <=tr.transactiondate 
		order by 1 desc
		) as rr(rate)
	join acc.rectypes_acqTypes ra on ra.receipttypeID=sr.receipttypeID
	outer apply (
		select top 1 aq.rate 
		from  acc.acquiring aq 
		where aq.acqTypeid= ra.acqTypeid 
			and aq.registerid = sr.registerid
			and aq.datestart<=tr.transactiondate
		order by aq.datestart desc
		) aq(rate)
	outer apply (
		select  top 1 c.rate
		from hr.commissions c
			where c.receipttypeid = sr.receipttypeID
			and c.date_start <= tr.transactiondate
			order by c.date_start desc
	) com(rate)
where s.saleID = @saleid
)
select 
	c.saleID,c.barcodeID, c.amount sale, cogs, netProfit, netProfit *.6 EAF, netProfit *.4 FAN, 
	c.amount * taxRate taxes, c.amount * renRate rent, c.amount * bankRate bankCommission, c.amount * comRate salesCommission
from cte c
