﻿use fanfan
go

if OBJECT_ID('hr.acrued_wages_f') is not null drop function hr.acrued_wages_f
go 

create function hr.acrued_wages_f ( ) returns table as return

	with _date (start_date) as (
		select DATEADD(dd,1, eomonth('20200101', -1))
	)
	, _periods (fin_period, n_days ) as (
		select EOMONTH(d.start_date, n.i-1), day(EOMONTH(d.start_date, n.i-1))
		from cmn.numbers n
			cross apply _date d
		where EOMONTH(d.start_date,n.i-1)<=EOMONTH(GETDATE(), 0)
	)
, _s as (
	select 
		s.saleID, 
		s.divisionID,
		t.transactiondate,	
		receipttypeID, 
		amount * case tt.transactiontypeid 
			when inv.transactiontype_id('RETURN') then -1
			else 1 end amount
	from inv.sales_receipts sr 
		join inv.transactions t on t.transactionID=sr.saleID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join inv.sales s on s.saleID=sr.saleID
)
, _sales (fin_period, divisionid, receipttypeid, amount) as (
select 
	EOMONTH(s.transactiondate, 0) fin_period, 
	divisionID, 
	receipttypeID, sum (amount) amount

from _s s
	join _periods p on p.fin_period=EOMONTH(s.transactiondate, 0)
group by EOMONTH(s.transactiondate, 0), divisionID, receipttypeID 
)
, _ful_comp (fin_period, hour_wage, positionid, positionnameid, num) as (
	select 
		fin_period, 
		c.hour_wage, 
		c.positionid,
		pn.positionnameid,
		ROW_NUMBER() over(partition by c.positionid, fin_period order by date_start desc)
	from _periods
		join  hr.compensation_schedule_21 c on date_start<=fin_period
					and ISNULL(date_finish, fin_period)>=fin_period
		join hr.positions_21 p on p.positionid=c.positionid
		join hr.position_names pn on pn.positionnameid=p.positionnameid
)
, _filtered (fin_period, positionid, positionnameid, hour_wage) as (
	select 
		fin_period, 
		positionid, 
		positionnameid, 
		hour_wage
	from _ful_comp
	where num =1 and hour_wage is not null
)
, t2 (fin_period, personid, positionnameid, has_MW, n, hour_wage) as (
select f.fin_period,
	s.personid, 
	f.positionnameid,
	s.has_MW, 
	ROW_NUMBER() over (partition by s.personid, fin_period order by s.date_start desc) n, 
	hour_wage
from _filtered f
join hr.schedule_21 s on s.positionid= f.positionid
			and ISNULL(s.date_finish, f.fin_period)>= f.fin_period
where s.personid not in (select org.person_id('ФЕДОРОВ А. Н.') union select org.person_id('ФЕДОРОВА И. В.') )
) 
, _actual_personnel (fin_period, personid, has_MW, hour_wage, person, positionnameid ) as (
	select 
		t2.fin_period, 
		t2.personid, 
		t2.has_MW, 
		t2.hour_wage,
		p.lfmname, 
		t2.positionnameid
	from t2 
		join org.persons p on p.personid = t2.personid
	where n =1
)
,_com (fin_period ,receipttypeid, rate, num) as (
	select fin_period, receipttypeid, rate, ROW_NUMBER () over (partition by c.receipttypeid, p.fin_period order by c.date_start desc)
	from _periods p join  hr.commissions c on date_start < p.fin_period
)
, _commissions (fin_period, divisionid, commission) as (
	select s.fin_period, s.divisionID, sum(s.amount * c.rate)
	from  _sales s
		join _com c on c.receipttypeid = s.receipttypeID and
			c.fin_period = s. fin_period 
	where c.num =1
	group by s.fin_period, s.divisionid
)
, _verified (fin_period, personid, has_MW, hour_wage, person, positionnameid, checktype, checktime, divisionid) as (
	select
		a.*, an.checktype,
	--a.fin_period, a.personid, a.has_MW, a.person
		case 
			when checktype=1 
					and CAST(checktime as time(0))<cast('10:00' as time(0)) 
					and superviserID is null 
					AND a.positionnameid NOT IN (7)
						then DATEADD(hh, 10, dbo.justdate(checktime))
				when checktype=0 
					and CAST(checktime as time(0))>cast('22:00' as time(0)) 
					and superviserID is null 
					AND a.positionnameid NOT IN (7)
							then DATEADD(hh, 22, dbo.justdate(checktime))
				else checktime end checktime, 
				org.workstation_division_id(an.workstationID, cast(an.checktime as date)) client_id 
	from _actual_personnel a 
		join org.attendance an on an.personID=a.personid
			and EOMONTH(an.checktime, 0)= a.fin_period
	where an.checktime< cast(getdate() as date)
)
, _hrs (fin_period, personid, person, divisionid, has_MW, hrs, hour_wage) as (
	select 
		v.fin_period, v.personid, v.person, v.divisionid, has_MW,
		sum(convert(money, v.checktime)*(1 - 2 * v.checktype)*24), 
		v.hour_wage
	from 
		_verified v
	group by v.fin_period, v.personid, v.person, v.divisionid, has_MW, hour_wage
)
, _f (fin_period, divisionid, PRLL, COMM) as (
	select 
		h.fin_period, h.divisionid, 
		sum (h.hrs * (h.hour_wage + hr.parameter_value_f('минималка/час', null) * hr.parameter_value_f('ЕСН', null)* has_MW))		
		amount,
		cast (isnull(c.commission, 0) as money) COMM
	from _hrs h 
		left join _commissions c on c.fin_period=h.fin_period and c.divisionid=h.divisionid
	group by h.fin_period, h.divisionid, (isnull(c.commission, 0))
)
select * from _f


go

declare @start_date date = '20220701';
select a.*, d.divisionfullname, sum (comm) over (partition by fin_period)
from hr.acrued_wages_f() a 
	join org.divisions d on d.divisionID= a.divisionid
order by 1 desc, 2;

go
