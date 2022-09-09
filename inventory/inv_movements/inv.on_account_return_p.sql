use fanfan
go
if object_id('inv.on_account_return_p') is not null drop proc inv.on_account_return_p
go

create proc inv.on_account_return_p 
	@barcodes barcodes_list readonly, 
	@date date, 
	@return_to varchar(20), 
	@user varchar (50), 
	@note varchar(max) output, 
	@sales bit = 'False'
as 
begin try
	begin transaction;

-- check if return goes to the place barcodes were taken from if @return_to is '' then to the same
-- else to @return_to
-- create transaction, CUST_CONSMT_RETURN type
-- move inventory barcodes to logstate and division
		declare @message varchar(max) = 'debuging';
		declare @divisionid int = 
			case @return_to 
				when '' then null else 
			(select divisionID from org.divisions where divisionfullname=@return_to )
			end;		
--		select @divisionid;
		declare @returnid int;
		if @sales = 'True' throw 50001, @message, 1

		insert inv.transactions (transactiondate, transactiontypeID, userID)
		values (@date, inv.transactiontype_id('CUST_CONSMT_RETURN'), org.person_id(@user));
		select @returnid = SCOPE_IDENTITY();
			
		
		with _tr as (select top 1 i.transactionID  
		from inv.inventory i 
			join @barcodes b on b.barcodeID= i.barcodeID
		order by i.transactionid desc
		)
		, s as (
		select 
			i.clientID, i.logstateID,
			case i.opersign 
				when -1 then isnull(@divisionid, i.divisionid)
				when 1 then i.divisionID 
			end divisionid, 
--			i.divisionID,
			@returnid transactionid, 
			-i.opersign opersign,
			i.barcodeID 
		from inv.inventory i
			join _tr t on t.transactionID= i.transactionID
			join @barcodes b on b.barcodeID= i.barcodeID
		)
		insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
		select clientID, logstateID, divisionID, transactionID, opersign, barcodeID
		from s;
		select @note = 'товар в количестве ' + cast((select count(*) from @barcodes) as varchar (max)) +
			' шт. принят в магазине' + case when @divisionid is null then ', где он был выдан '
				else + ' ' + @return_to end

		;throw 50001, @note, 1
	commit transaction
end try
begin catch
	select @note= ERROR_MESSAGE()
	rollback transaction
end catch
go

set nocount on; 
declare @date date = '20220909', 
@return_to varchar(20) =  '07 ФАНФАН', 
@user varchar(50) =  'ФЕДОРОВ А. Н.', 
@note varchar(max); 
declare @barcodes barcodes_list; 
insert @barcodes values (636841), (658811), (659785), (662590); 
exec inv.on_account_return_p 
	@barcodes = @barcodes, 
	@date = @date, 
	@return_to = @return_to , 
	@user = @user , 
--	@sales= 'True',
	@note = @note output; 
select @note; 



