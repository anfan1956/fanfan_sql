go
CREATE OR ALTER FUNCTION inv.inventoryAfterDate(@startDate as date) returns table
	as Return


SELECT 
	gi.Ведомость
	, bi.*
FROM inv.GetAvailableBarcodesAfterDate(@startDate) gi
Outer Apply
	inv.barcodeid_info_f(gi.barcodeid) as bi

go
DECLARE @startDate DATE = '20251008';

select * from inv.inventoryAfterDate (@startDate)

