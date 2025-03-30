USE [fanfan]
GO

/****** Object:  View [rep].[v_employees_in_out]    Script Date: 26.03.2025 14:11:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





ALTER view rep.v_employees_in_out
	as 
	with
	_in as (
		select	wd.divisionID, att.personID, att.checktype, att.attendanceID as id_in,
				att.checktime,				
				row_number() over(partition by att.personID, wd.divisionID, dbo.justdate( att.checktime ) order by att.checktime ) ncheck
		from org.attendance att
			join org.workstationsdivisions wd on wd.workstationID = att.workstationID
				and isnull( wd.datefinish, getdate())>=dbo.justdate(getdate())
			join org.divisions d on d.divisionID = wd.divisionID
									and ( isnull( d.datefinish, '20991231' ) >= dbo.justdate( att.checktime ) 
											and d.datestart <= dbo.justdate( att.checktime ) )
		where att.checktype = 1 --and att.personID>1
	),
	_out as (
		select	wd.divisionID, att.personID, att.checktype, att.attendanceID as id_out,
				att.checktime,
				row_number() over(partition by att.personID, wd.divisionID, dbo.justdate( att.checktime ) order by att.checktime ) ncheck
		from org.attendance att
			join org.workstationsdivisions wd on wd.workstationID = att.workstationID
			join org.divisions d on d.divisionID = wd.divisionID
									and ( isnull( d.datefinish, '20991231' ) >= dbo.justdate( att.checktime ) 
											and d.datestart <= dbo.justdate( att.checktime ) )
		where att.checktype = 0 -- and att.personID>1
	)
	select	p.lfmname, d.divisionfullname as division, dbo.justdate( i.checktime ) as date,
			cast( cast( i.checktime as time( 0 ) ) as varchar( 5 ) ) as in_fact,
			isnull( cast( cast( o.checktime as time( 0 ) ) as varchar( 5 ) ), '' ) as out_fact,
			round( cast( datediff( mi, i.checktime, isnull( o.checktime, i.checktime ) ) as float ) / 60, 2 ) as duration,
			i.divisionID, i.personID, i.id_in, o.id_out
	from _in i
		left join _out o on i.divisionID = o.divisionID
							and i.personID = o.personID
							and dbo.justdate( i.checktime ) = dbo.justdate( o.checktime )
							and i.ncheck = o.ncheck
		join org.persons p on p.personID = i.personID
		join org.divisions d on d.divisionID = i.divisionID

GO


