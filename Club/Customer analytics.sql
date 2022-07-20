use fanfan
go
if OBJECT_ID('club.cust_turnover_f') is not null drop function club.cust_turnover_f
go
create function club.cust_turnover_f(@num_months int) returns table as return
	with _startdate (startdate, transactionid)  as (
			select top 1 t.transactiondate, t.transactionID
			from inv.transactions t order by 2 
	)

	, s  (amount, customerid, customer, phone, stdate) as (
			select 
				sum(isnull(sg.amount, 0)) amount, p.personID, p.lfmname,
				c.connect, sd.startdate
			from cust.persons p 
				join cust.connect c on c.personID=p.personID and c.prim='True'
				left join inv.sales s on p.personID = s.customerID
				left join inv.sales_goods sg on sg.saleID=s.saleID
				left join inv.transactions t on t.transactionid =s.saleID
				cross apply _startdate sd
			where isnull(t.transactiondate, sd.startdate)>=iif	(@num_months>0, 
					DATEADD(MM,  -@num_months, GETDATE()), sd.startdate)
				and connecttypeID=1
			group by p.personID, p.lfmname, c.connect, sd.startdate
	)

	select amount, customerid, customer, phone, stdate,  
			RANK() over(order by s.amount desc) cust_rank
	from s
	where s.amount> iif (@num_months = 0, -1, 0)
go
select * from club.cust_turnover_f(12)