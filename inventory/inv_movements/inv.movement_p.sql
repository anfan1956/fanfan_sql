use fanfan
go

create or alter proc inv.movement_p @user varchar(max), @outId int, @inId int, @barcodes inv.barcode_type readonly 
as 
	set nocount on;
	declare @note varchar(max);
	begin try
		begin transaction
		
		declare 
			@transactionid int
			, @typeid int = inv.transactiontype_id('MOVEMENT')
			, @logstateid int = inv.logstate_id ('IN-Warehouse')
			, @clientiD int  = org.client_id (@outid)
			, @rowcount int;

		insert inv.transactions (
			  transactiondate
			, transactiontypeID
			, userID) 
		select 
			transactiondate			= GETDATE(),
			transationtypeid		= @typeid,
			userid					= org.person_id (@user);

		set @transactionid = SCOPE_IDENTITY();

		insert into inv.inventory(
			clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
		select 
			  clientid				= @clientiD
			, logstateid			= @logstateid
			, divisionid			= _seed.divisionid
			, transactionid			= @transactionid
			, opersign				= _seed.opersign
			, barcodeid				= b.barcodeid
		from @barcodes b
			outer apply	(
				select @outid, -1
				union all
				select @inId, 1
			) as _seed (divisionid, opersign);
		
		set @rowcount = @@ROWCOUNT;

--		select @note = 'debugging'  ; 
--		this one  is form testing and debugging
--		throw 50001, @note, 1;
		commit transaction
		select @note = 
					'transaction:' + 
					cast (@transactionid as varchar) + 
		' succeded. ' + cast(@rowcount /2 as varchar ) + ' barcodes moved'
		select @note
	end try
	begin catch
		rollback transaction
		select @note = '' + error_message () 
		select @note;
	end catch
go

set nocount on;
declare @barcodes inv.barcode_type;

with _order (barcodeid) as (
	select distinct i.barcodeID
	from inv.inventory i 
	where i.transactionID = 91782	
)
, _invTake as (
	select distinct i.barcodeID
	from inv.inventory i 
	where i.transactionID = 91783	
) 
insert into @barcodes
select barcodeid from _order 
except
select barcodeid from _invTake;
;
select * from @barcodes



declare 
	@outid int = 27, 
	@inid int = 35,
	@user varchar (50) = 'Федоров А. Н.';
/*
exec inv.movement_p 
		 @user =@user, 
		 @outId = 27, 
		 @inId = 35, 
		 @barcodes =@barcodes;
*/
