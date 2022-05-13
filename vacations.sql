/*This is going to represent whole procedure of approving and charging vacations
if vacation is approved - authorityID is not null - then vacation charges could be charged
if charge is made then vacation is considered to be taken
only full time positions are entitled for the vacation
некоторые выходят на пенсию, после чего им отпускные не начисляются.
*/

declare @date date = '20220226'; -- условная дата расчета отпускных
declare @charge_start date = dateadd(M, -6, @date); -- начало расчета отпускных
declare  @personid int = 10 ; -- расчет для А.Балушкиной
with _source (personid, positionnameid, date_start, positionname, num) as (
	select 
		s.personid, pn.positionnameid, date_start , pn.positionname, 
		ROW_NUMBER() over (partition by s.personid, pn.positionnameid order by s.date_start desc) 
	from hr.schedule_21 s 
		join hr.positions_21 p on p.positionid=s.positionid
		join hr.position_names pn on pn.positionnameid=p.positionnameid
	where s.has_MW = 'True' and 
	isnull(s.date_finish, GETDATE())>= @date
)
select s.personid, positionnameid, vacation_date, vacationyear, v.num_of_weeks 
from _source s 
	join hr.vacations v  on v.personid =s.personid
where s.num=1 and v.personid =10 and taken = 'false'
/*
	авторизовать отпуск или нет - вопрос другой процедуры
	сейчас  нужно создать функцию отработанного времени и процент среди других продавцов
	за отпускной период
*/
