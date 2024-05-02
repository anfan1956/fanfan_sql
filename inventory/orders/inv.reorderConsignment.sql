use fanfan
go

if OBJECT_ID ('inv.reorderConsignment') is not null drop proc inv.reorderConsignment
go

create proc inv.reorderConsignment  @date date, @shop varchar (max), @user varchar(max), @barcodes dbo.barcodes_list readonly 
as 
set nocount on;
declare @message varchar (max)= 'Just debugging', @transId int;


begin try
	begin transaction
		insert inv.transactions(transactiondate, transactiontypeID, userID)
		values (@date, inv.transactiontype_id('Consignment'), org.user_id(@user))
		select @transId = SCOPE_IDENTITY();

		with _seed (divisionid, logstateid, opersign) as (
			select org.division_id(@shop), inv.logstate_id('IN-WAREHOUSE'), 1
			union all 
			select 0, inv.logstate_id('EXTERNAL'), -1
		)
		insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
		select 619, s.logstateid, s.divisionid, @transId, s.opersign, b.barcodeID
		from @barcodes b
		cross apply _seed s;

		select @transId;
--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
	select ERROR_MESSAGE()
	rollback transaction
end catch
go
		

set nocount on; declare @barcodes dbo.barcodes_list; insert @barcodes values (667743), (667758), (667761); 
--exec inv.reorderConsignment '20240416', '05 УИКЕНД', 'ФЕДОРОВ А. Н.', @barcodes;

select distinct ordertype from inv.invTake_info_(667473)

select inv.barcodeorder_id(667743)
