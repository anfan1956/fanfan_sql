USE [fanfan]
GO
/****** Object:  UserDefinedFunction [hr].[hours_lastperiod]    Script Date: 31.07.2022 22:30:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [hr].[hours_lastperiod](@startdate date) returns table as return

with _enddate (enddate) AS (
	SELECT sd.salary_date 
	FROM hr.salary_dates sd
	WHERE sd.salary_date >=DATEADD(d, -1, @startdate)
	ORDER BY sd.salary_date ASC
	OFFSET 1 ROWS
	FETCH NEXT 1 ROWS ONLY
)
, _ids as (
		select distinct s.personid
		from hr.position_names pn
			join hr.positions_21 p on p.positionnameid = pn.positionnameid
			join hr.schedule_21 s on s.positionid =p.positionid
		where pn.positionname like 'консультант%' and personid<>1
	)
	, _verified (personid, checktype, checktime, clientid, salary_date) as (
		select 
			a.personID, a.checktype,
				case 
					when checktype=1 
						and CAST(checktime as time(0))<cast('10:00' as time(0)) 

						and superviserID is null 
							then DATEADD(hh, 10, dbo.justdate(checktime))
					when checktype=0 
						and CAST(checktime as time(0))>cast('22:00' as time(0)) 
						and superviserID is null 
							 then DATEADD(hh, 22, dbo.justdate(checktime))
					else checktime end checktime, 
					org.workstation_client_id(a.workstationID, cast(a.checktime as date)) client_id, 
					e.enddate
		from org.attendance a 
			join _ids i on i.personid=a.personID
			JOIN _enddate e ON e.enddate>=CAST(a.checktime AS date)
			--join _periods p on cast(a.checktime as date) between  p.start_date and p.salary_date
			WHERE CAST(a.checktime AS DATE) >=@startdate

	)
	select 
		distinct a.salary_date, clientid, a.personID,
		sum(convert(money, a.checktime)*(1 - 2 * a.checktype)*24) over(partition by a.personid, a.clientid, a.salary_date) hrs
		/* с детализацией по  дням */
	--	distinct a.personID, sum(convert(money, a.checktime)*(1 - 2 * a.checktype)*24) over(partition by a.personid) hr
	from _verified a
GO
----функция считала отработанные часы за все время, а не за период

DECLARE @startdate DATE = '20220701';
SELECT * FROM hr.hours_lastperiod(@startdate) hl
WHERE hl.personID= 67