if OBJECT_ID('cust.custAllData_v') is not null drop view cust.custAllData_v
go 
create view cust.custAllData_v as
with 
_countTotal (custid, salesNum ) as (
	select 
		s.customerID,
		count(s.saleID)
	from inv.sales s
		join inv.transactions t on t.transactionID=s.saleID
		group by s.customerid
), 
_countYear (custid, sYear, num) as (
	select 
		s.customerID, DATEPART(yyyy, t.transactiondate), 
		count(s.saleID)
	from inv.sales s
		join inv.transactions t on t.transactionID=s.saleID
		group by s.customerid, DATEPART(yyyy, t.transactiondate) 
)
select 
	p.personID custid, 
	p.lname, p.fname, p.mname, p.gender, p.birthdate, 
	c.connect, 
	s.saleID, 
	format (t.transactiondate, 'dd.MM.yyyy') saleDate, DATEPART(yy, t.transactiondate) sYear, 
	DATEPART(MM, t.transactiondate) sMonth, 
	cu.num salesPerYear,
	ct.salesNum salesNumTotal, 
	tt.transactiontype, d.divisionfullname shop, ps.lfmname salesperson, rt.r_type_rus, sr.amount paidType, 
	sg.barcodeID, sg.amount totalAmount, sg.price totalPrice, br.brand, 
	st.article, it.inventorytype, cl.color, sz.size, st.cost 

from cust.persons p
	join cust.connect c on c.personID=p.personID and  c.connecttypeID= 1
	join inv.sales s on s.customerID=p.personID
	join inv.sales_receipts sr on sr.saleID=s.saleID
	join inv.sales_goods sg on sg.saleID=s.saleID
	join inv.transactions t on t.transactionid=s.saleID
	join org.divisions d on d.divisionID=s.divisionID
	join org.persons ps on ps.personID=s.salepersonID
	join fin.receipttypes rt on rt.receipttypeID=sr.receipttypeID
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	join inv.barcodes bc on bc.barcodeID=sg.barcodeID
	join inv.styles st on st.styleID=bc.styleID
	join inv.inventorytypes it  on it.inventorytypeID=st.inventorytypeID
	join inv.brands br on br.brandID=st.brandID
	join inv.colors cl on cl.colorID=bc.colorID
	join inv.sizes sz on sz.sizeID=bc.sizeID
	join inv.orders o on  o.orderID=st.orderID
	join _countYear cu on cu.custid=p.personID and cu.sYear=DATEPART(YYYY,t.transactiondate)
	join _countTotal ct on ct.custid=p.personID
	join org.chains ch on ch.chainID=d.chainID
where p.personID not in (1)

go
select * from cust.custAllData_v
