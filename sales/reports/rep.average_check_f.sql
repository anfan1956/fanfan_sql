use fanfan
go

if OBJECT_ID('rep.average_check_f') is not null drop function rep.average_check_f
go
create function rep.average_check_f(@divisionid int, @n int) returns table as return

-- @n количество месяцев
	with s (amount, saleid) as (
	select sum(sg.amount), sg.saleID
	from inv.sales s
		join inv.transactions t on t.transactionID=s.saleID
		join inv.sales_goods sg on sg.saleID=s.saleID
	where 
		s.divisionid =@divisionid
		and t.transactiondate>=cast(DATEADD(MM, -@n, getdate())as date)
	group by sg.saleID	
	)	
	select *, sum(amount) over ()/ COUNT(amount) over () av_check
	from s
go

declare @divisionid int = 18, @n int = 6

select * from rep.average_check_f(@divisionid, @n	)