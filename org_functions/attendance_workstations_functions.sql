USE fanfan
GO
IF OBJECT_ID('org.attendance_date_shop_f') IS NOT NULL DROP FUNCTION org.attendance_date_shop_f
GO
CREATE FUNCTION org.attendance_date_shop_f (@divisionid int, @date DATE) RETURNS 
TABLE AS  RETURN

	SELECT DISTINCT a.personID, P.lfmname person
	FROM org.attendance a 
		JOIN org.persons p ON p.personID = a.personID
	WHERE a.workstationID in (SELECT * FROM org.division_stations_f(@divisionid))
	AND dbo.justdate(a.checktime) = dbo.justdate(@date)
go

SELECT person FROM org.attendance_date_shop_f(18, getdate()) adsf

IF OBJECT_ID('org.workstation_id') IS NOT NULL DROP FUNCTION org.workstation_id
GO
CREATE FUNCTION org.workstation_id(@workstation VARCHAR (25)) RETURNS INT AS 
BEGIN
	DECLARE @workstationid INT;
	SELECT @workstationid = w.workstationID FROM org.workstations w
		WHERE w.workstation= @workstation;
	RETURN @workstationid
END
GO

IF OBJECT_ID('org.division_stations_f') IS NOT NULL DROP FUNCTION org.division_stations_f
GO
CREATE FUNCTION org.division_stations_f(@divisionid int) RETURNS 
TABLE AS RETURN

WITH  _w (workstationID, divisionid, num) AS (
	SELECT w.workstationID, wd.divisionID,  
		ROW_NUMBER() OVER(PARTITION BY w.workstationID ORDER BY wd.datestart DESC)
	FROM org.workstations w
		JOIN org.workstationsdivisions wd 
			ON wd.workstationID=w.workstationID
)
SELECT workstationID
FROM _w
WHERE num=1 AND _w.divisionid= @divisionid
GO
