use fanfan
go
declare @date date = '20221025';
declare @saleid int = 74331;
with _i as (
	select i.*, c.customerid
	from sms.instances i
		join sms.instances_customers c on c.smsid= i.smsid
	where i.smsdate >=@date
)
select s.*, i.customerid, i.discount, p.lfmname, t.transactiondate, cp.lfmname 
from inv.sales s
	join inv.transactions t on t.transactionID=s.saleID
	left join _i i on i.customerid= s.customerID
	join org.persons p on p.personID = s.salepersonID
	join cust.persons cp on cp.personID=s.customerID
where t.transactiondate>=@date
order by 1

select * from inv.sales_goods s where s.saleID=@saleid


declare @sales_un table (saleid int)
insert @sales_un values (74333), (74331)
select * from @sales_un
declare @sales_code table (saleid int)
insert @sales_code values (74319), (74315), (74316)
select u.saleid false, r.saleid req from @sales_un u, @sales_code r
