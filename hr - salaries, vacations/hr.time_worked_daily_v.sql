USE [fanfan]
GO

ALTER view [hr].[time_worked_daily_v] as

with  _persons as 
	---здесь немного коряво, по-индийски
	(select distinct personid, departmenttypeid
		from hr.positions_21 p 
			join hr.schedule_21 s on s.positionid=p.positionid
			join hr.position_names pn on pn.positionnameid=p.positionnameid
		where p.hour_wage ='true'
		and pn.positionname in ('Консультант', 'консультант/совм')
)

, _attd as 
	(select a.* ,
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
				p.departmenttypeid
		from org.attendance a
			join _persons p on p.personid=a.personID)

, _daily (personid, checkdate, время, departmenttypeid) as 
		(select a.personID,  cast(checktime as date) checkdate, 
			round(SUM (convert(money, a.t_verified)*24*(1-2*checktype)),2) время, a.departmenttypeid
		From _attd a
		group by a.personID, cast(checktime as date), a.departmenttypeid
		having abs(SUM (convert(money, a.t_verified)*24*(1-2*checktype)))<24)

, _final (personid, сотрудник, Дата, Год, Неделя, половина, месяц, время, департамент) as 
		(select  p.personID, p.lfmname, 
			cast (d.checkdate as datetime), 
			 DATEPART (YYYY, checkdate), 
			 DATEPART (WK, checkdate), 
			 case when DATEPART (DD, checkdate) <=15 then 1 else 2 end половина, 
			 FORMAT(checkdate, 'MMMM', 'ru-ru') месяц, d.время,
			 dt.departmenttype
		from _daily d 
			join org.persons p on p.personID=d.personID
			join org.departmenttypes dt on dt.departmenttypeid=d.departmenttypeid
			)
select * from _final

GO


