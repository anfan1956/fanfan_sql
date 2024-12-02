use fanfan
go

if OBJECT_ID ('inv.printTimeUpdate') is not null drop proc inv.printTimeUpdate
go

create proc inv.printTimeUpdate   @bcodes inv.barcode_type readonly, @priceSetId varchar(255), @divisionid int, @filtered bit 
as 
set nocount on;

declare @idString nvarchar(max)
SET @idString = REPLACE(REPLACE(@pricesetid, '(', ''), ')', '');
SELECT value AS ID
INTO #TempIDs
FROM  STRING_SPLIT(@idString, ',');
update #TempIDs set ID = TRIM(ID)

declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction;
		if  @filtered = 'False'
			begin
				--select * 
				update p set p.printtime= CURRENT_TIMESTAMP
				from inv.pricesets_divisions p 
					where 1=1
						and p.divisionID = @divisionid 
						and p.pricesetID in (SELECT ID FROM #TempIDs)
						and  p.barcodeID in (select * from @bcodes)
				select @@ROWCOUNT
			end
		else 
			begin
				--select * 
				update p set p.printtime= CURRENT_TIMESTAMP
				from inv.pricesets_divisions p 
					where 1=1
						and p.divisionID = @divisionid 
						and p.pricesetID in (SELECT ID FROM #TempIDs)
				select @@ROWCOUNT
			end
			
--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
--	select ERROR_MESSAGE()
	rollback transaction
end catch
