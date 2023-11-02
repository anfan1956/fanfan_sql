if OBJECT_ID('inv.invTake_post') is not null drop proc inv.invTake_post
go
create proc inv.invTake_post @takeid int  as
	set nocount on;
begin try
	begin transaction
		;
		with
		_bc (barcodeid) as (select t.barcodeid from inv.invTake_barcodes t where t.takeid= @takeid)
		, _previous (barcodeid, logstateID, divisionID, clientID, opersign, transactionid) as (
		select i.barcodeid, i.logstateID, i.divisionID, i.clientID, -1, @takeid 
		from _bc t 
			join inv.inventory i on i.barcodeID=t.barcodeid
		group by  i.barcodeid, i.logstateID, i.divisionID, i.clientID
		having sum (i.opersign)>0
		)
		, _current (barcodeid, logstateID, divisionID, clientID, opersign, transactionid) as (
			select b.barcodeid, inv.logstate_id('in-warehouse'), it.divisionid, org.client_id(divisionID), 1, b.takeid
			from inv.invTake_barcodes b
				join inv.inventorytakes it on it.inventorytakeID=b.takeid
			where b.takeid=@takeid
		)
		, _final as (
		select barcodeid, logstateID, divisionID, clientID, opersign, transactionid from _previous
		union all 
		select barcodeid, logstateID, divisionID, clientID, opersign, transactionid from _current
		)
		insert inv.inventory(barcodeid, logstateID, divisionID, clientID, opersign, transactionid)
		select barcodeid, logstateID, divisionID, clientID, opersign, transactionid from _final
		;
		update it set it.closed= 1
		from inv.inventorytakes it
		where it.inventorytakeID =@takeid



	select @takeid takeid, 'инвентаризация записана' msg
	commit transaction
end try
begin catch
	select 0 , ERROR_MESSAGE()
	rollback transaction
end catch

go

declare @takeid int = 79629

--exec inv.invTake_post 79629
select * from inv.inventory where transactionID = @takeid
select * from inv.inventorytakes where inventorytakeID= @takeid

