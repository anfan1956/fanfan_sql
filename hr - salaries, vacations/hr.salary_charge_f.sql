USE [fanfan]
GO
/****** Object:  UserDefinedFunction [hr].[salary_charge_f]    Script Date: 31.07.2022 22:11:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [hr].[salary_charge_f](@startdate date, @update date) returns table as return
with s (commissions) as (
	select sum(sales * rate) 
	from hr.sales_commissions_f(@startdate)
) 
, f (personID, hrs, clientid, commissions,hourly_wage, min_wage, PIT,SocTax, charge_date) as (
	select h.personID, h.hrs, h.clientid, 
		h.hrs/sum(h.hrs) over () * s.commissions,
		hr.actual_hourcharge_salespeople(@startdate) * h.hrs,
		h.hrs * hr.parameter_value_f('минималка/час', null) * w.has_MW ,
		h.hrs * hr.parameter_value_f('минималка/час', null) * hr.parameter_value_f('ставка НДФЛ', null) * w.has_MW,
		h.hrs * hr.parameter_value_f('минималка/час', null) * hr.parameter_value_f('ЕСН', null) * w.has_MW, 
		@update
		--h.hrs/sum(h.hrs) over () * s.commissions + hr.actual_hourcharge_salespeople(@startdate) *h.hrs total
	from hr.hours_lastperiod(@startdate) h
		join hr.has_MW_f(@update) w on w.personid=h.personID
		cross apply s
	)
,  r (charge_date, personid, clientid, journalid, detailsid, amount, accountid) as (
select charge_date, personID, clientid, 
	anfan_release.acc.journalid_func('hard cash'), 
	anfan_release.acc.transaction_details_id ('комиссионные'), 
	commissions,
	anfan_release.acc.accountid_func('комиссионные', 'RUR') from f union
select charge_date, personID, clientid, 
	anfan_release.acc.journalid_func('hard cash'),
	anfan_release.acc.transaction_details_id ('оклад, нал'), 
	hourly_wage - min_wage,
		anfan_release.acc.accountid_func('оклад', 'RUR') from f union
select charge_date, personID, clientid, 
	anfan_release.acc.journalid_func('payroll'),
	anfan_release.acc.transaction_details_id ('оклад, банк'), 
	min_wage - PIT,
	anfan_release.acc.accountid_func('оклад', 'RUR') from f union
select charge_date, personid, clientid, 
	anfan_release.acc.journalid_func('payroll'),
	anfan_release.acc.transaction_details_id ('НДФЛ'), 
	PIT, 
		anfan_release.acc.accountid_func('НДФЛ', 'RUR') from f union
select charge_date, personid, clientid,anfan_release.acc.journalid_func('payroll') ,
	anfan_release.acc.transaction_details_id ('ЕСН'), 
	SocTax,
	anfan_release.acc.accountid_func('ЕСН', 'RUR')   from f 
)
select r.*, t.details

--, anfan_release.acc.accountid_func('зарплата к оплате', 'RUR') account
from r
	join anfan_release.acc.transactiondetails t on t.detailsid=r.detailsid

/*following to be deleted*/
--where personid = 67
GO
declare @startdate date = dateadd(d, 1, hr.last_date())
DECLARE  @update date = hr.upcoming_date() 

SELECT * from hr.salary_charge_f(@startdate, @update) s
WHERE s.personid =67



