USE [fanfan]
GO
/****** Object:  UserDefinedFunction [hr].[accrued_wages3_f]    Script Date: 26.09.2022 01:21:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---declare @startdate date = '20210601';
ALTER function [hr].[accrued_wages3_f] (@startdate date) returns table as return
	with _commissions as 
	(
		select distinct 
			cast (s.mdate as datetime) mdate, 
				min_wage, 
				sc.hour_wage,  
				receipttypeid, 
				rate * c.has_commission rate, 
				has_MW, sc.position,  
				sc.personid, pr.lfmname, sc.departmenttypeid
		from hr.salary_charge_dates (@startdate) s
			cross apply hr.latest_comm_rates_date_f(s.mdate)
			join hr.comp_sched_top_f (@startdate) c on c.mdate=s.mdate
			join hr.schedule_top_f (@startdate) sc on sc.positionid=c.positionid
			join org.persons pr on pr.personID=sc.personid
		where 
			--sc.position in ('консультант', 'консультант/совм')
			sc.departmenttypeid = org.departmenttype_id ('розница')
			and sc.hour_wage='true'
	)
	,_sales as 
	(
	select s.*, t.transactiondate, mdate, sr.receipttypeID,
		case tt.transactiontype 
			when 'RETURN' then - abs(sr.amount)
			else abs(sr.amount) end amount
	from inv.sales s
		join inv.transactions t on t.transactionID=s.saleID
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join inv.sales_receipts sr on sr.saleID=s.saleID
		join hr.salary_charge_dates (@startdate) ch on cast(t.transactiondate as date)<=ch.mdate
			and cast(t.transactiondate as date)>case 
				when DATEPART(dd, mdate)<=15 then EOMONTH(mdate, -1)
				else  DATEFROMPARTS (YEAR(mdate), month(mdate), 15) end
	)
	, _sales_agr as (
	select sum (amount) amount, mdate, receipttypeID  
	from _sales
	group by mdate, receipttypeID
	)
, _persons as 
	(
		select distinct personid, p.departmenttypeid
		from hr.positions_21 p 
			join hr.schedule_21 s on s.positionid=p.positionid
		where 
			p.hour_wage='true' and 
			p.position in ('Консультант', 'консультант/совм')
	)
, _attd (personid, checktime, checktype, t_verified, departmenttypeid, clientid) as (
	select 
		--a.* , 
		a.personid, a.checktime, a.checktype, 
			case 
				when checktype=1 
					and CAST(checktime as time(0))<cast('10:00' as time(0)) 
					and superviserID is null 
					and p.departmenttypeid=org.departmenttype_id('розница')
						then DATEADD(hh, 10, dbo.justdate(checktime))
				when checktype=0 
					and CAST(checktime as time(0))>cast('22:00' as time(0)) 
					and superviserID is null 
					and p.departmenttypeid=org.departmenttype_id('розница')
						 then DATEADD(hh, 22, dbo.justdate(checktime))
				else checktime end t_verified, 
				p.departmenttypeid, org.workstation_clientid_f (a.workstationID, a.checktime)
	from org.attendance a
		join _persons p on p.personid=a.personID
	where checktime>=@startdate
	)
, _daily (personid, checkdate, время, departmenttypeid, clientid) as 
	(
	select a.personID,  cast(checktime as date) checkdate, 
		round(SUM (convert(money, a.t_verified)*24*(1-2*checktype)),2) время, 
		a.departmenttypeid, a.clientid
	From _attd a
		where a.checktime between @startdate and cast( GETDATE() as date) 
	group by a.personID, cast(checktime as date), a.departmenttypeid, a.clientid
	having abs(SUM (convert(money, a.t_verified)*24*(1-2*checktype)))<24
	)
, _halfmonthly (время, personid, mdate, departmenttypeid, clientid) as (
	select sum (d.время) время, d.personID, ch.mdate, d.departmenttypeid, clientid
	from _daily d
		join hr.salary_charge_dates (@startdate) ch on d.checkdate<=ch.mdate
			and d.checkdate>case 
				when DATEPART(dd, mdate)<=15 then EOMONTH(mdate, -1)
				else  DATEFROMPARTS (YEAR(mdate), month(mdate), 15) end
	group by personID, mdate, d.departmenttypeid, clientid
	)
, _share (personid, время, share, mdate, departmenttypeid, clientid) as 
	(
	select h.personID, h.время, 
		convert (float, h.время)/sum(h.время) over (partition by h.mdate, h.departmenttypeid order by h.mdate ) share, 
		h.mdate, h.departmenttypeid, clientid
	from _halfmonthly h
	join org.persons p on p.personID=h.personID 
	)
, _base (personid, время, проц_участия, форма_оплаты, ставка, начисление, период, departmenttypeid, clientid) as 
	(
		select sh.personid, sh.время, sh.share, 'почасовая', 1, c.hour_wage * sh.время, sh.mdate, s.departmenttypeid, sh.clientid
		from hr.comp_sched_top_f(@startdate) c
			join hr.schedule_top_f(@startdate) s on s.positionid=c.positionid and c.mdate=s.mdate
			join _share sh on sh.personid=s.personid and sh.mdate=c.mdate
		where c.hour_wage is not null
	)
, _office (personid, время, проц_участия, форма_оплаты, ставка, начисление, период, departmenttypeid, clientid)
	as (select s.personid, null, null, 'оклад', null, c.fixed_wage/2, s.mdate, s.departmenttypeid, p.clientid
		from hr.comp_sched_top_f(@startdate) c
			join hr.schedule_top_f(@startdate) s on s.positionid=c.positionid and c.mdate=s.mdate
			join hr.positions_21 p on p.positionid=s.positionid
		where c.fixed_wage is not null

)
, _com_report (personid, время, проц_участия, форма_оплаты, ставка, начисление, период, departmenttypeid, clientid) as
	(select 
		s.personID, s.время, s.share, rt.receipttype, c.rate, 
		sa.amount* share*rate, 
		cast (sa.mdate as datetime), 
		c.departmenttypeid, s.clientid
	from _share s
		join _sales_agr sa on sa.mdate=s.mdate
		left join _commissions c on c.personid=s.personID 
			and c.mdate=s.mdate
			and c.receipttypeid=sa.receipttypeID
		left join fin.receipttypes rt on rt.receipttypeID=c.receipttypeid
		join org.departmenttypes dt on dt.departmenttypeid=c.departmenttypeid
	where sa.amount* share*rate<>0
	)
, _united (personid, время, проц_участия, форма_начисления, ставка, начисление, период,  departmenttypeid, clientid) as 
(
	select * from _base
	union 
	select * from _com_report
	union 
	select * from _office

)
, _final as (
select  p.lfmname сотрудник, u.время, u.проц_участия, u.форма_начисления, u.ставка, 
		u.начисление, u.период, dt.departmenttype департамент, 
		u.personid, u.departmenttypeid, cl.clientRus компания, cl.clientID
	from _united u
	join org.persons p on p.personID=u.personid
	join org.departmenttypes dt on dt.departmenttypeid=u.departmenttypeid
	join org.clients cl on cl.clientID=u.clientid
	)
select *
from _final p
go

select * from hr.accrued_wages3_f('20210601') p
where период = '20220915' and p.personid = 7
