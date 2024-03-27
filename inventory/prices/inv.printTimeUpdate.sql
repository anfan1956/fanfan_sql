use fanfan
go

if OBJECT_ID ('inv.printTimeUpdate') is not null drop proc inv.printTimeUpdate
go

create proc inv.printTimeUpdate  @bcodes inv.barcode_type readonly, @priceSetId int, @divisionid int, @filtered bit 
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction;
		if  @filtered = 'False'
			begin
				--select * 
				update p set p.printtime= CURRENT_TIMESTAMP
				from inv.pricesets_divisions p 
					where p.divisionID = @divisionid 
						and p.pricesetID = @priceSetId			
						and  p.barcodeID in (select * from @bcodes)
				select @@ROWCOUNT
			end
		else 
			begin
				--select * 
				update p set p.printtime= CURRENT_TIMESTAMP
				from inv.pricesets_divisions p 
					where p.divisionID = @divisionid 
						and p.pricesetID = @priceSetId			
				select @@ROWCOUNT
			end
			
--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
--	select ERROR_MESSAGE()
	rollback transaction
end catch
go
		
