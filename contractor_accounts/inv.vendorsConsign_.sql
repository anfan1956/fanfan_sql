declare @startdate date = '20241101';

if OBJECT_ID('inv.vendorsConsign_') is not null drop function inv.vendorsConsign_
go 
create function inv.vendorsConsign_ (@startDate date = '20241101') returns table as 
return
select distinct c.contractor showroom, s.showroomID
from inv.transactions t
	join inv.orders o on o.orderID = t.transactionID	
	join inv.orderclasses oc on oc.orderclassID = o.orderclassID
	join org.showrooms s on s.showroomID = o.showroomID
	join org.contractors c on c.contractorID=s.showroomID
where 1=1
	and oc.orderclass = 'CONSIGNMENT'
	and transactiondate>=@startdate

go
select showroomID, showroom from inv.vendorsConsign_(default)
select showroomid, showroom from inv.vendorsConsign_(default)