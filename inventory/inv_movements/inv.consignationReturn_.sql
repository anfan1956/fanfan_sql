use fanfan
go

if OBJECT_ID ('inv.consignationReturn_') is not null drop proc inv.consignationReturn_
go

create proc inv.consignationReturn_ @info inv.barcode_type readonly,  @json varchar (max) output
as 
set nocount on;
	declare @message varchar (max)= 'Just debugging'
begin try
		begin transaction

		declare @header table (field varchar(max), value varchar(max));
--		declare @inventory table (clientid int, logstateid int, divisionid int, transactionid int, opersign int, barcodeid int)
		declare 
			@date datetime, 
			@shop varchar(max), 
			@user varchar(max), 
			@listType varchar(max), 
			@showrooom varchar(max), 
			@transid int; 

		with s (field, value)  as 
			(select field, value 
				from OPENJSON(@json)
				with (
					field varchar(max) '$.field',
					value varchar(max) '$.value'
				) as jsonValue	
			)
		insert @header (field, value)
		select field, value from s;

		select @date = CONVERT(datetime, value, 104) from @header h where h.field='date';	
		select @shop = value from @header h where h.field='shop'; 
		select @user  = value from @header h where h.field='user';
		select @listType  = value from @header h where h.field='listType';
		select @showrooom  = value from @header h where h.field='showroom';
	
		--select @date transDate, @shop shop, @user username, @listType transType, @showrooom showroom;
		insert inv.transactions (transactiondate, transactiontypeID, userID)
		select @date, inv.transactiontype_id(@listType), org.person_id(@user)
		select @transid = SCOPE_IDENTITY();
		--select * from inv.transactions t where t.transactionID=@transid;

		with s (clientid, divisionid, opersing, logstateid) as (
			select org.contractor_id(@showrooom), 0, 1, inv.logstate_id ('EXTERNAL') 
			union all select null, null, -1, null
		)
		insert inv.inventory (clientID, logstateID, divisionID, transactionID, barcodeID, opersign)
		select 
			isnull(s.clientid, i.clientID) clientid, 
			isnull(s.logstateid, i.logstateID) logstateid, 
			isnull(s.divisionid, i.divisionID) divisionid, 
			@transid transactionID, 
			i.barcodeID, 
			s.opersing
		from @info iv
			join inv.inventory i on iv.barcodeid=i.barcodeid
			cross apply s
		where i.logstateID = inv.logstate_id('IN-WAREHOUSE')
		group by 
			i.clientID, s.clientid, 
			i.divisionID, 			
			i.barcodeID, 
			s.divisionid, s.opersing, 
			i.logstateID, 
			s.logstateid
		having sum(i.opersign)>0;
--		select * from @inventory;
		select @message  =  'transaction # ' + cast(@transid as varchar(max)) + ' recorded'		
		select @message;
		--;throw 50001, @message, 1
		commit transaction
end try
begin catch
		select ERROR_MESSAGE()
		rollback transaction
end catch
go	

set nocount on; declare @json varchar(max) = 
'[
	{"field":"date","value":"21.02.2024"},{"field":"shop","value":"05 УИКЕНД"},
	{"field":"user","value":"ФЕДОРОВ А. Н."},{"field":"listType","value":"CONSIGNMENT RETURN"},
	{"field":"showroom","value":"ВИТАЛИК"},{"field":"qty","value":"3"},{"field":"cost","value":"135000"}
]'
		, @info inv.barcode_type; 
		insert @info values (666706), (666707), (667733); 
--exec inv.consignationReturn_ @info = @info, @json = @json; 
