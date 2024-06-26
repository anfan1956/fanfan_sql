use fanfan
go

if OBJECT_ID('cust.customer_id_name') is not null drop function cust.customer_id_name
go
create function cust.customer_id_name (@saleid int ) returns table as return
	select 
		s.customerID, 
		lfmname customer, 
		isnull(c.connect, 'N/A') connect, 
		d.divisionfullname division, 
		s.fiscal_id
	from inv.sales s 
		join cust.persons p on p.personID =s.customerID
		join org.divisions d on d.divisionID=s.divisionID
		left join cust.connect c on c.personID = s.customerID 
			and c.connecttypeID=1 and c.prim = 'true'
	where s.saleID= @saleid

go

select * from cust.customer_id_name(81073)
select * from inv.sales s where s.saleID= 81073
select * from cust.customer_id_name(81074)

select s.*, 
	t.transactiondate, sr.amount, sr.receipttypeID	
from inv.sales s 
	join inv.transactions t on t.transactionID=s.saleID
	join inv.sales_receipts sr on sr.saleID=s.saleID

where s.saleID in (81073, 81074)
order by 1 desc