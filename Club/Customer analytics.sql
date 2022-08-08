use fanfan
go
if OBJECT_ID('club.cust_turnover_f') is not null drop function club.cust_turnover_f
go
create function club.cust_turnover_f(@months INT = null, @startdate DATE = NULL) returns table as return
	with _transactions (transactionid)  as (
			select T.transactionID
			from inv.transactions t 
				JOIN inv.sales_trans_types_v s ON s.transactiontypeID=t.transactiontypeID
			WHERE 
			CAST(T.transactiondate AS DATE) >=
				DATEADD(m,-ISNULL(@months, 12), ISNULL(@startdate, CAST(GETDATE() AS DATE))) 
				AND 
			CAST(t.transactiondate AS DATE) <= ISNULL(@startdate, CAST(GETDATE()AS DATE))
	)
	, _sales_volume (customerID, phone, customer, amount ) AS (
		SELECT 

			s.customerID,
			c.connect phone,
			P.lfmname,
			sum (sg.amount) amount
		FROM _transactions t
			JOIN inv.transactions tr ON tr.transactionID=t.transactionid
			JOIN inv.sales_goods sg ON sg.saleID=t.transactionid
			JOIN inv.sales s ON s.saleID=t.transactionid
			JOIN cust.persons p ON p.personID= s.customerID
			JOIN cust.connect c ON c.personID=p.personID
		WHERE c.connecttypeID=1
		GROUP BY s.customerID, p.lfmname, c.connect
	)
SELECT 
	amount,
	RANK() OVER (ORDER BY amount desc) cust_rank,
	customer,
	phone, 
	customerID 
FROM _sales_volume
WHERE amount>0
go

select amount, cust_rank, customer, phone, customerid from club.cust_turnover_f(12, '20220701')
ORDER BY 2 

GO

