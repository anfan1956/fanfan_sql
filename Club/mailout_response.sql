use fanfan
go
declare @date date = '20221110';
declare @saleid int = 74331;
with _i as (
	select i.*, c.customerid
	from sms.instances i
		join sms.instances_customers c on c.smsid= i.smsid
	where i.smsdate >=@date
)
select s.*, i.customerid, i.discount, p.lfmname, t.transactiondate, cp.lfmname 
--update s set s.sms_promo = 'True'
from inv.sales s
	join inv.transactions t on t.transactionID=s.saleID
	left join _i i on i.customerid= s.customerID
	join org.persons p on p.personID = s.salepersonID
	join cust.persons cp on cp.personID=s.customerID
where t.transactiondate>=@date and i.customerid<>1
order by 1
go

--alter table inv.sales add sms_promo bit null


select * from inv.sales