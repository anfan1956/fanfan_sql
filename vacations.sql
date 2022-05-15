/*This is going to represent whole procedure of approving and charging vacations
if vacation is approved - authorityID is not null - then vacation charges could be charged
if charge is made then vacation is considered to be taken
only full time positions are entitled for the vacation
некоторые выходят на пенсию, после чего им отпускные не начисляются.
*/


/*Создаем функцию с датой и количестом недель отпуска для сотрудника, утвержденного но еще не отгулянного*/
if OBJECT_ID ('hr.vacation_params_f') is not null drop function hr.vacation_params_f
go
create function hr.vacation_params_f (@personid int ) returns table as return
	with _vac_date (vac_date) as (select vacation_date from hr.vacations where personid = @personid and taken = 'false')	
	, _source (personid, positionnameid, date_start, positionname, num) as (
		select 
			s.personid, pn.positionnameid, date_start , pn.positionname, 
			ROW_NUMBER() over (partition by s.personid, pn.positionnameid order by s.date_start desc) 
		from hr.schedule_21 s 
			join hr.positions_21 p on p.positionid=s.positionid
			join hr.position_names pn on pn.positionnameid=p.positionnameid
			cross apply _vac_date v
		where s.has_MW = 'True' and 
		isnull(s.date_finish, GETDATE())>= v.vac_date
	)
	select s.personid, positionnameid, vacation_date, vacationyear, v.num_of_weeks, DATEADD(WK, -1, vacation_date) vac_charge_date 
	from _source s 
		join hr.vacations v  on v.personid =s.personid
	where s.num=1 and v.personid =@personid and taken = 'false'
go

/*
	авторизовать отпуск или нет - вопрос другой процедуры
	сейчас  нужно создать функцию отработанного времени и процент среди других продавцов
	за отпускной период
	нужно будет поправить процедуру регистрации персонала
*/

-- Функция расчета отпускных (наличная часть)
if OBJECT_ID ('hr.vacation_charge_f') is not null drop function  hr.vacation_charge_f
go 

create function hr.vacation_charge_f (@personid int) returns table as return
with 
_params as (select * from hr.vacation_params_f(@personid))

--selecting and checking authorised working time for the period used to calc vac charge
, _attd (personid, attn_date, t_verified, checktype, vac_charge_date) as (
	select 
		a.personID, cast (checktime as date), 		
			case 
				when checktype=1 
					and CAST(checktime as time(0))<cast('10:00' as time(0)) 
					and superviserID is null 
						then DATEADD(hh, 10, dbo.justdate(checktime))
				when checktype=0 
					and CAST(checktime as time(0))>cast('22:00' as time(0)) 
					and superviserID is null 
						 then DATEADD(hh, 22, dbo.justdate(checktime))
				else checktime end, 
				a.checktype, 
				p.vac_charge_date
	from org.attendance a 
		cross apply _params p
	where 
		a.personID not in (1) and
		a.checktime between dateadd(M, - hr.parameter_value_f('мес/расчет/отпуск',null), p.vac_charge_date) and p.vac_charge_date
)

--checking all the persons eligible to take part in common hours
, _hr_wage (positionnameid, hour_wage, num) as (
	select p.positionnameid, c.hour_wage, ROW_NUMBER () over (partition by p.positionnameid order by date_start desc)
	from hr.compensation_schedule_21 c
		join hr.positions_21 p on p.positionID = c.positionid		
		cross apply _params pr
	where c.date_start <=pr.vac_charge_date and min_wage is not null
)	
, _persons (personid, hour_wage) as (
	select distinct s.personid, w.hour_wage
	from hr.schedule_21 s 
		join hr.positions_21 p on p.positionid=s.positionid
		join hr.position_names pn on pn.positionnameid=p.positionnameid
		join org.persons ps on ps.personID=s.personid
		cross apply _params pm
		join _hr_wage w on w.positionnameid=p.positionnameid
	where 
		isnull(s.date_finish, GETDATE())>= dateadd(M, -hr.parameter_value_f('мес/расчет/отпуск',null), pm.vac_charge_date) and
		positionname like 'консуль%' and
		num = 1
)

-- calculating persons total hours worked  and hour wage
, f (personid, hrs, hour_wage) as (
	select  
		a.personid, sum (convert (money, t_verified) * (1 - 2 * checktype) * 24), 
		ps.hour_wage
	from _attd a 
		join org.persons p on p.personID= a.personid
		join _persons ps on ps.personid=a.personid
	group by a.personid, ps.hour_wage
)

-- ставки комиссионных за все периоды
, _all_commissions (date_start, reciepttypeid, rate, num) as (
	select c.date_start, c.receipttypeid, c.rate, ROW_NUMBER () over (partition by receipttypeid order by date_start desc) num
	from hr.commissions c 
)

-- ставки комиссионных,  действующие на период начала отпуска
, _commissions (reciepttypeid, rate)  as (
select a.reciepttypeid, a.rate 
from  _all_commissions a
	join fin.receipttypes r on r.receipttypeID=a.reciepttypeid
where a.num=1
)

-- выручка за расчетный период
, _sales as (
	select sum (sg.amount) amount, s.receipttypeID
	from inv.sales_goods sg
		join inv.sales_receipts s on s.saleID=sg.saleID
		join inv.transactions t on t.transactionID  = s.saleID
		cross apply _params pm
	where t.transactiondate between dateadd(M, - hr.parameter_value_f('мес/расчет/отпуск',null), pm.vac_charge_date) and pm.vac_charge_date
	group by s.receipttypeID
)

-- всего комиссионных в деньгах по всем ставкам
, commissions (commissions) as (
	select sum(s.amount * c.rate) commissions   
	from _sales s
		join _commissions c on c.reciepttypeID=s.receipttypeID
)

-- расчет для всех за расчетный период сотрудника
, _sf (personid, комиссия, почасовая) as (
	select f.personid,
		f.hrs/sum(f.hrs)  over () * c.commissions /hr.parameter_value_f('мес/расчет/отпуск',null)/4 * pm.num_of_weeks  commission
		, hrs * (f.hour_wage-hr.parameter_value_f('минималка/час', null)) /hr.parameter_value_f('мес/расчет/отпуск',null)/4 * pm.num_of_weeks hourly
	from f 
		cross apply commissions c
	cross apply _params pm
)
select * from _sf where personid = @personid
go

declare  @personid int = 10 ; -- расчет для А.Балушкиной
select * from hr.vacation_charge_f (@personid)
