if OBJECT_ID('cust.saleIdData_v') is not null drop view cust.saleIdData_v
go 
create view cust.saleIdData_v as
select 
	p.personID custid, p.lname, p.fname, p.mname, p.gender, p.birthdate, 	c.connect, s.saleID, 
	format (t.transactiondate, 'dd.MM.yyyy') saleDate, DATEPART(yy, t.transactiondate) sYear, 
	DATEPART(MM, t.transactiondate) sMonth, tt.transactiontype, d.divisionfullname shop, ps.lfmname salesperson, chain,
	sum (sg.amount ) amount

from cust.persons p
	join cust.connect c on c.personID=p.personID 
	join inv.sales s on s.customerID=p.personID
	join inv.sales_goods sg on sg.saleID=s.saleID
	join inv.transactions t on t.transactionid=s.saleID
	join org.divisions d on d.divisionID=s.divisionID
	join org.persons ps on ps.personID=s.salepersonID
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	join inv.barcodes bc on bc.barcodeID=sg.barcodeID
	join inv.styles st on st.styleID=bc.styleID
	join inv.inventorytypes it  on it.inventorytypeID=st.inventorytypeID
	join inv.brands br on br.brandID=st.brandID
	join inv.orders o on  o.orderID=st.orderID
	join org.chains ch on ch.chainID=d.chainID
where p.personID not in (1) and c.connecttypeID=1 
and c.connect  like '9%'
and c.connect not like '9000%'

group by 
	p.personID, p.lname, p.fname, p.mname, p.gender, p.birthdate, c.connect, s.saleID, 
	format (t.transactiondate, 'dd.MM.yyyy'), DATEPART(yy, t.transactiondate), 
	DATEPART(MM, t.transactiondate), tt.transactiontype, d.divisionfullname, ps.lfmname, chain  
	  

go
select * from cust.saleIdData_v
