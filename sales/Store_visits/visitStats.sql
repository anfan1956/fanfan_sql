WITH TimeIntervals AS (
    SELECT 
        CAST('10:00:00' AS TIME) AS StartTime,
        CAST('11:00:00' AS TIME) AS EndTime
    UNION ALL
    SELECT 
        DATEADD(HOUR, 1, StartTime) AS StartTime,
        DATEADD(HOUR, 1, EndTime) AS EndTime
    FROM TimeIntervals
    WHERE StartTime < CAST('22:00:00' AS TIME)
)
, _final as (
SELECT 
    cast(StartTime as datetime) StartTime,
	isnull(v.divisionid, 27) divisionid ,
	count (id) as vCount
FROM TimeIntervals
	left join 
	cust.visit v on 
	cast (v.visitTime as time) >= StartTime and
	cast (v.visitTime as time) < EndTime
Group by StartTime, EndTime, divisionid
)
select  
	FORMAT(ts.StartTime, 'HH:mm tt', 'ru-ru') AS TimeInterval
from _final ts;


