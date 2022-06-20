use fanfan
go
if OBJECT_ID('club.cust_turnover_f') is not null drop function club.cust_turnover_f
go
create function club.cust_turnover_f(@num_months int) returns table as return
	with s (сумма, customerid, ФИЩ, телефон) as (
		select 
			sum(sg.amount) amount, s.customerID, p.lfmname,
			c.connect
		from inv.sales s 
			join inv.sales_goods sg on sg.saleID=s.saleID
			join inv.transactions t on t.transactionid =s.saleID
			join cust.persons p on p.personID = s.customerID
			join cust.connect c on c.personID=p.personID and c.prim='True'
		where t.transactiondate > DATEADD(MM, -@num_months,  GETDATE())
		group by s.customerID, p.lfmname, c.connect
	)
	select *,  
			RANK() over(order by s.сумма desc) ранжир
	from s
	where s.сумма>0
go
--select * from club.cust_turnover_f(6)