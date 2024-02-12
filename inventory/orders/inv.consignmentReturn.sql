use fanfan
go

if OBJECT_ID ('inv.consignmentReturn') is not null drop proc inv.consignmentReturn
go

create proc inv.consignmentReturn  @info dbo.id_Type readonly, @userid int
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction
	declare @r int;
	declare @date datetime = getdate()
	
	insert inv.transactions (transactiondate, transactiontypeid, userid, modified)
	select @date , inv.transactiontype_id('consignment return') , @userid , @date 
	select @r = SCOPE_IDENTITY();
	with _seed (logstateid, opersign) as (
			select inv.logstate_id('EXTERNAL'), 1 
			union all
			select null, -1
		)
	, s (barcodeid, logstateid, divisionid, clientid, opersign ) as (
		select iv.barcodeID, iv.logstateID, iv.divisionID,  iv.clientID, sum(iv.opersign)
		from @info i
			join inv.inventory iv on iv.barcodeID=i.Id
		where iv.logstateID = inv.logstate_id('IN-WAREHOUSE') 
		group by iv.barcodeID, iv.logstateID, iv.divisionID,  iv.clientID
		having sum(iv.opersign)>0
	)
	insert inv.inventory (barcodeID, logstateID, divisionID, clientID, opersign, transactionID)
	select s.barcodeid, isnull(se.logstateid, s.logstateid) logstateid , s.divisionid, s.clientid, 
		se.opersign, @r transactionid
	from s	cross apply _seed se
	;
	--;throw 50001, @message, 1
	commit transaction
	return @r;
end try
begin catch
	select ERROR_MESSAGE()
	rollback transaction
end catch
go



set nocount on; declare @info dbo.id_Type; insert @info values (667754), (667861), (667853), (667848); declare @r int, @userid int = 1; 
--exec @r = inv.consignmentReturn @info, @userid; select @r;
--exec inv.transaction_delete 81102
select * from inv.invTake_info_(667853)
select * from inv.transactions t order by 1 desc
