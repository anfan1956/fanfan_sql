
if OBJECT_ID('fin.P_L_func') is not null drop function fin.P_L_func
go
create function fin.P_L_func(@start_date date) returns table as return

	with _periods (fin_period) as (
		select EOMONTH(@start_date, n.i-1)
		from cmn.numbers n
		where EOMONTH(@start_date,n.i-1)<=EOMONTH(GETDATE(), 0)
	)
	, _sales (divisionid, amount, GOGS, fin_period, sales_month, sales_year) as (
		select g.divisionID, sum(g.amount), sum(-g.cost_FOB * 1.3 ), g.sales_period, g.sales_month, g.sales_year
		from fin.gross_p_l_func(@start_date) g
		group by g.divisionID, g.sales_period,
			g.sales_month, g.sales_year
	)
	select s.divisionid, s.amount, s.GOGS, s.fin_period, s.sales_month, s.sales_year , rent_objectid, - s.amount * r.turnover_rate tn_over_rcharge
	from fin.rent r
		cross apply _periods p
		join _sales s on s.divisionid= r.divisionid
				and s.fin_period = p.fin_period
go

declare @start_date date = '20220801';
select * from fin.P_L_func(@start_date)
