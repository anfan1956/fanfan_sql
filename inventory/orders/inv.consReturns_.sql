if OBJECT_ID ('inv.consReturns_') is not null drop function inv.consReturns_
go
create function inv.consReturns_ (@date date) returns table as return
select 
	t.transactionID returnid,
	t.transactiondate, tt.transactiontype, i.barcodeID, u.username,
	c.contractor vendor, c2.contractor showroom, br.brand, st.article, cl.color, 
	sz.size, 
	tr.transactiondate consigned_on
from inv.transactions t 
	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
	join inv.inventory i  on i.transactionID= t.transactionID
	join org.users u on u.userID = t.userID
	join inv.barcodes b on b.barcodeID = i.barcodeID
	join inv.styles st on st.styleID=b.styleID
	join inv.orders o on o.orderID=st.orderID
	join inv.transactions tr on tr.transactionID=o.orderID
	join org.contractors c on c.contractorID=o.vendorID
	join org.contractors c2 on c2.contractorID=o.showroomID
	join inv.brands br on br.brandID=st.brandID
	join inv.colors cl on cl.colorID=b.colorID
	join inv.sizes sz on sz.sizeID=b.sizeID

where tt.transactiontypeID = inv.transactiontype_id('CONSIGNMENT RETURN') 
	and t.transactiondate > @date
	and i.logstateID in (15)
go
declare @date date = '20240101'

select * from inv.consReturns_(@date)
order by 1 desc
select * from inv.consReturns_('20240101')