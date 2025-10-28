go
CREATE OR ALTER FUNCTION inv.inventoryAfterDate(@startDate as date) returns table
	as Return


SELECT 
	  gi.Ведомость
	, gi.магазин
	, bi.*
FROM inv.GetAvailableBarcodesAfterDate(@startDate) gi
cross Apply
	inv.barcodeid_info_f(gi.barcodeid) as bi

go
DECLARE @startDate DATE = '20251008';

select  * from inv.inventoryAfterDate (@startDate) i
select * from inv.barcodeid_info_f(505297)
