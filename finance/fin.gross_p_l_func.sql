use fanfan
go

if OBJECT_ID('fin.gross_p_l_func') is not null drop function fin.gross_p_l_func
go
create function fin.gross_p_l_func(@date_start date) returns table as return


-- create report to show current day financial based on pure cost and rate

select 
	s.saleid, 
	d.divisionfullname shop, 
	d.divisionID,
	p.lfmname sales_pers,
	cp.lfmname customer,
	sg.barcodeID, 
	sg.amount, 
	st.cost * cr.rate cost_FOB, 
	sg.amount- cr.rate*st.cost * 1.3 gross_DDP, 
	sg.amount/cr.rate/st.cost/1.3 margin_GR, 
	st.article,
	br.brand, 
	it.inventorytyperus category, 
	cast (cast (t.transactiondate as date) as datetime) sales_date,
	cast(EOMONTH(t.transactiondate, 0) as datetime) sales_period, 
	DATEPART(yyyy,t.transactiondate) sales_year , 
	DATEPART(MM,t.transactiondate) month_num, 
	lower(FORMAT(t.transactiondate, 'MMM')) sales_month 
from inv.sales s
	join inv.transactions t on t.transactionID = s.saleID
	join inv.sales_goods sg on sg.saleID=s.saleID
	join inv.barcodes b on b.barcodeID= sg.barcodeID
	join inv.styles st on st.styleID=b.styleID
	left join inv.orders o on o.orderID = st.orderID
	join cmn.currentrates cr on cr.currencyID=isnull(o.currencyID, st.currencyid)
	join inv.brands br on br.brandID=st.brandID
	join inv.inventorytypes it on it.inventorytypeID=st.inventorytypeID
	join org.divisions d on d.divisionID=s.divisionID
	join org.persons p on p.personID = s.salepersonID
	join cust.persons cp on cp.personID = s.customerID
	
where cast( t.transactiondate as date) >=  @date_start
go

declare @barcodeid int = 529299
declare @date_start date =  '20200101'
select * from fin.gross_p_l_func(@date_start) g
where g.barcodeID =@barcodeid
