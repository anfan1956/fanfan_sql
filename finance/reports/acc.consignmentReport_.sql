if OBJECT_ID('acc.consignmentReport_') is not null drop function acc.consignmentReport_
go
create function acc.consignmentReport_ (@vendor varchar(max), @account varchar(max)) returns table as return
/* 
	сначала вычисляем все по блоку продаж , для того, чтобы потом сделать left join with 
	acc.transactions которые включают и платежи, transdate позже
*/
with  q (saleid, barcodeid,  receipttypeid, registerid, bankid, transtype, brandid, catid, article, orderid, 
			showroomid, saleAmt, colorid, sizeid, rate, num) 
as (
	select 
		sg.saleID, sg.barcodeid, sr.receipttypeID, sr.registerid, r.bankid, 
		inv.transaction_type_f(t.transactiontypeID) transtype, st.brandID, st.inventorytypeID, st.article, 
		o.orderid, o.showroomID,
		sum (sg.amount) over (partition by sg.saleid)
		, b.colorID, b.sizeID, a.rate, 
		ROW_NUMBER() over (partition by sg.saleid, b.barcodeid order by a.id desc)
	from  inv.sales_goods sg
		join inv.sales_receipts sr on sr.saleID=sg.saleID
		join inv.transactions t on t.transactionID=sg.saleID
		join inv.barcodes b on b.barcodeID=sg.barcodeID
		join inv.styles st on st.styleID=b.styleID
		join inv.orders o on o.orderID=st.orderID and o.orderclassID =3
		join acc.rectypes_acqTypes aa on aa.receipttypeID=sr.receipttypeID
		join acc.acquiring a 
			on a.acqTypeid = aa.acqTypeid 
			and a.registerid=sr.registerid
			and a.datestart<=t.transactiondate		
		join acc.registers r on r.registerid= sr.registerid
	--where sg.saleID = @saleid
)
select 
	t.transactionid, isnull(q.transtype, 'PAYMENT') transtype, 
	t.transdate,	
	ar.article item,
	t.amount * (2 * e.is_credit- 1) amount, 
	br.brand, it.inventorytyperus category, q.article, q.orderid, c.contractor showroom, 
	q.barcodeid,q.saleAmt, 
	t.document, 
	t.comment, 
			isnull(
		CASE 
			WHEN ISNUMERIC(SUBSTRING(r.account, 1, 1)) = 1 THEN r.account
			ELSE 
			STUFF(right(r.account, len(r.account)-2), 3, 0, ' ') 
		END, 
		cast(t.saleid as varchar(max))) [register/saleid], 
	isnull(c2.contractor, c3.contractor) bank,  
	rt.receipttype, 
	format(q.rate, '#,##0.00%') rate, 
	cl.color, 
	sz.size
from acc.transactions t
	join acc.articles ar on ar.articleid=t.articleid
	join acc.entries e on e.transactionid=t.transactionid
	join acc.entries e2 on e2.transactionid=t.transactionid and e2.is_credit<>e.is_credit
	left join q on q.saleid = t.saleid and q.num=1 and q.barcodeid=t.barcodeid
	left join inv.brands br on br.brandID=q.brandid
	left join inv.sizes sz on sz.sizeID=q.sizeid
	left join inv.colors cl on cl.colorID=q.colorid
	left join inv.inventorytypes it on it.inventorytypeID=q.catid
	left join org.contractors c on c.contractorID=q.showroomid
	left join fin.receipttypes rt on rt.receipttypeID=q.receipttypeid
	left join acc.registers r on r.registerid = e2.registerid
	left join org.contractors c2 on c2.contractorID=r.bankid
	left join org.contractors c3 on c3.contractorID=q.bankid
where
	e.accountid = acc.account_id(@account)
	and e.contractorid= org.contractor_id(@vendor)	
	--and t.saleid =@saleid
go

declare @date date = '20240101', @account varchar(max) ='счета к оплате', @contractor varchar(max)='E&N suppliers', @saleid int  = 81288
declare @trid int = 7832;
select * from acc.consignmentReport_(@contractor, @account) r --where r.[register/saleid] = cast(@saleid as varchar(max))
order by 1

--select sg.* , tt.transactiontype, t.transactiondate, br.brand
--from inv.sales_goods sg 
--	join inv.transactions  t on t.transactionID=sg.saleID
--	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
--	join inv.barcodes b on b.barcodeID=sg.barcodeID
--	join inv.styles st on st.styleID =b.styleID
--	join inv.brands br on br.brandID = st.brandID
--	join inv.orders o on o.orderID=st.orderID
--where o.orderclassID =3
--	and sg.saleID = @saleid



--select * from acc.transactions t where t.saleid =@saleid
