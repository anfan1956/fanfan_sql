if OBJECT_ID('acc.current_cash_v') is not null drop view acc.current_cash_v
go
create view acc.current_cash_v 
as

	select 
		f.registerid, 
		f.клиент, 
		f.банк, 
		cast (f.дата_но as datetime) дата_НО, 
		u.lfmname оператор,
		sum(f.сумма) расчетная,
		null фактическая,
		cr.currencycode валюта,
		r.rate * sum(f.сумма) суммаRUR, 
		f.счет_банк регистр
	from acc.registers_cashflow_f(getdate()) f
		join cmn.currencies cr on cr.currencyID=f.currencyid
		join cmn.currentrates r on r.currencyid=cr.currencyid
		join acc.beg_entries_around_date_f(getdate()) b on b.registerid=f.registerid
		join org.persons u on u.personID =b.bookkeeperid

	group by 
		f.registerid, 
		f.банк,
		f.дата_но,
		f.клиент,
		cr.currencycode,
		u.lfmname, 
		f.счет_банк,
		r.rate
go
select * from acc.beg_entries_today_v;
select * from acc.beg_entries_today2_v 
select * from acc.current_cash_v
