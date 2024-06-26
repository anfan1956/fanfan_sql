﻿use fanfan
go
if OBJECT_ID('fin.P_L_func') is not null drop function fin.P_L_func
go
declare @start_date date = '20220731';
go
create function fin.P_L_func(@start_date date) returns table as return

	with _date (start_date) as (
		select DATEADD(dd,1, eomonth(@start_date, -1))
	)
	, _periods (fin_period, n_days ) as (
		select EOMONTH(d.start_date, n.i-1), day(EOMONTH(d.start_date, n.i-1))
		from cmn.numbers n
			cross apply _date d
		where EOMONTH(d.start_date,n.i-1)<=EOMONTH(GETDATE(), 0)
	)

	, _sales (divisionid, amount, COGS, fin_period, sales_month, sales_year, month_num) as (
		select g.divisionID, 
			sum(g.amount), 
			sum(-g.cost_FOB * 1.3 ), 
			g.sales_period, 
			g.sales_month, 
			g.sales_year, 
			g.month_num
			from _date d
		cross apply fin.gross_p_l_func(d.start_date ) g
		group by g.divisionID, g.sales_period,
			g.sales_month, g.sales_year, month_num
	)
, f as (
	select 
		s.divisionid, 
		s.amount SALES, 
		cast(s.COGS as money) COGS, 
		s.fin_period, 
		s.sales_month, 
		s.sales_year, 
		r.rent_objectid, 
		cast (-iif(s.amount * r.turnover_rate> 
		ro.footage * isnull(r.rent_per_meter_year, 0 )/12 * cr.rate, 
		s.amount * r.turnover_rate, ro.footage * 
			isnull(r.rent_per_meter_year, 0 )/12 * cr.rate )*(1+VAT) as money)
			RENT,
		cast(iif(s.amount * r.turnover_rate> 
		ro.footage * isnull(r.rent_per_meter_year, 0 )/12 * cr.rate, 
		'turnover', 'base') as varchar(15)) rent_type,
		s.month_num, 
		-cast (ac.PRLL as money) PRLL, 
		-cast (ac.COMM as money) CoMiSN
	from _sales s
		join  _periods p on p.fin_period =s.fin_period
		left join fin.rent r on s.divisionid= r.divisionid
		left join fin.rent_objects ro on ro.rent_objectid= r.rent_objectid
		join cmn.currentrates cr on cr.currencyID = r.currencyid
		join hr.acrued_wages_f() ac on ac.divisionid=s.divisionid and ac.fin_period= s.fin_period
)
, unpvt as (
select divisionid, fin_period, sales_month, sales_year, rent_objectid, rent_type, month_num, amount, account 
from (select * from f) f 
unpivot ( amount for account in (SALES, COGS, RENT, PRLL, CoMiSN)) as unpvt
)
, _other as (
select sum(e.amount) amount, org.division_id('ОФИС') divisionid, oe.expense_type account, p.fin_period
from fin.other_expenses e
	join fin.other_exense_types oe on oe.expense_typeid=e.expense_typeid
cross apply _periods p
group by oe.expense_type, p.fin_period
)
select 
	isnull(u.divisionid, o.divisionid) divisionid, 
	isnull (u.fin_period, o.fin_period) fin_period, 
	isnull (u.sales_month, lower(format(o.fin_period, 'MMM')) ) sales_month, 
	isnull (u.sales_year, DATEPART(yyyy, o.fin_period)) sales_year,
	u.rent_objectid, 
	isnull(u.rent_type, 'backoffice') charge_type,
	isnull (u.month_num, DATEPART(MM, o.fin_period)) month_num, 
	isnull(u.amount, -o.amount) amount, 
	isnull (u.account, o.account ) account
from unpvt u
full join _other o on o.fin_period = u.fin_period and o.divisionid= u.divisionid

go

declare @start_date date = '20220731';
select * from fin.P_L_func(@start_date)
order by 1 desc

