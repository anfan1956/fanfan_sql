USE [fanfan]
GO

ALTER procedure inv.priceset_printed_mark @pricesetID varchar(255), @workstation varchar( 128 )
as
begin
	set nocount on;


declare @idString nvarchar(max)
SET @idString = REPLACE(REPLACE(@pricesetid, '(', ''), ')', '');
SELECT value AS ID
INTO #TempIDs
FROM  STRING_SPLIT(@idString, ',');
update #TempIDs set ID = TRIM(ID)


	update pd set pd.printtime = getdate()
	from inv.pricesets_divisions pd
	where 1=1
		and pd.pricesetID in (SELECT ID FROM #TempIDs)
		and divisionID = org.division_id_ws( @workstation )

	return 0
end