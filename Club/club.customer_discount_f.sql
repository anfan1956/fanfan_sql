USE [fanfan]
GO
/****** Object:  UserDefinedFunction [club].[customer_discount_f]    Script Date: 24.08.2022 21:54:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [club].[customer_discount_f] (@personid int) returns table as return 

with 
_base_discount(bd)  AS (SELECT .03)
, _programs (personid, discountlevelid, customermode) as
 (
	select top 1 personID, discountlevelID, customermode 
	from cust.persons_programs pp 
	where pp.personID=@personid
	order by 2 desc 
 )
 --select * from _programs
, _tot (personid, customer, total) as 
(
	select p.personID, p.lfmname, sum (isnull(g.amount, 0)) total
	from cust.persons p
		left join inv.sales s on s.customerID=p.personID
		left join inv.sales_goods g on g.saleID=s.saleID
		join inv.transactions t on t.transactionID=s.saleID
	where p.personID=@personid and t.transactiondate>=DATEADD(YYYY, -1, dbo.justdate(getdate()))
	group  by p.personID, p.lfmname
)

, _turn (personid, customer, _turn) as 
(
	select p.personID, p.lfmname, sum (isnull (g.amount, 0)) total
	from cust.persons p
		left join inv.sales s on s.customerID=p.personID
		left join inv.sales_goods g on g.saleID=s.saleID
		left join inv.transactions t on t.transactionID=s.saleID
			
	where	p.personID=@personid and t.transactiondate>=DATEADD(YYYY, -1, cast(getdate() as date))
	group  by p.personID, p.lfmname
)
--select * from _turn
, _m_turn as
(
	select t.personid, t.customer, t._turn, d.discountlevelId, d.discount
	from _turn t
	left join cust.discount_levels d on d.max_amount>t._turn and d.min_amount<=t._turn
)
, _f as (
select t.personid, t.customer, t.total, m._turn, isnull (m._turn, 0) turn, pp.customermode mode, 
	case(pp.customermode) 
		when 'M' then pp.discountlevelID
		when 'A' then iif(m.discountlevelID=1 and t.total>0, 2, m.discountlevelid) end discountlevelid
from _tot t
	left join _m_turn m on m.personid= t.personid
	left join _programs pp on pp.personID=t.personid 
union
select p.personid, p.lfmname, 0, 0, 0, 'A', 1
	from cust.persons p
	where p.personID=@personid 
)
select top 1 f.personid,  
	CASE f.personid WHEN 1 THEN 0
		else
	IIF(d.discount=0, b.bd, D.discount) * 100 END discount 
	, f.discountlevelid, f.customer

from _f f join cust.discount_levels d on d.discountlevelID=f.discountlevelid
CROSS APPLY _base_discount b
order by f.discountlevelid desc
go

DECLARE @cust_id INT = 4;
SELECT * FROM club.customer_discount_f(@cust_id) cdf