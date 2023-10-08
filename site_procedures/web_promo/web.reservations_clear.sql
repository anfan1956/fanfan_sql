if OBJECT_ID('web.reservations_clear') is not null drop  proc web.reservations_clear
go
create proc web.reservations_clear as

declare @transactions table(transactionid int);

insert @transactions
select t.transactionID 
from inv.transactions t 
where t.transactiontypeID in (32, 33, 34, 39) ;
declare @n int = (select count(*) from @transactions);
--select t.transactionid, ROW_NUMBER() over(order by transactionid)  num from @transactions t;

declare @transid int
declare @i int=1
declare 
	@res int, 
	@JobName varchar(max);


while @i<=@n
begin;
	with t (transactionid, num) as (
		select t.transactionid, ROW_NUMBER() over(order by transactionid)  num
		from @transactions t
	)
	select @transid = transactionid
	from t  where num = @i;
	exec inv.transaction_delete @transid

	select	@JobName = cast(@transid as varchar(max));

	IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name = @Jobname)
		BEGIN
			exec @res = msdb.dbo.sp_delete_job 
				@job_name =  @JobName,  
				@delete_unused_schedule = 'True';	
		END;
	select @i=@i+1;
end

go

select t.transactionID 
from inv.transactions t 
where t.transactiontypeID in (32, 33, 34) 

--exec web.reservations_clear

select * from web.promo_log
--select barcodeID from inv.inventory where transactionID = 71427

--select sum(i.opersign )
--from inv.inventory i  
--	--join inv.transactions t on t.transactionID=i.transactionID	
--where i.barcodeID = 651524 
--	and i.logstateID=inv.logstate_id('in-warehouse')

--select i.* , tt.transactiontypeID, tt.transactiontype, d.divisionfullname
--from inv.inventory i 
--	join inv.transactions t on t.transactionID= i.transactionID
--	join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
--	join org.divisions d on d.divisionID=i.divisionID
--where i.barcodeID = 651524
--order by i.transactionID desc

select * From inv.site_reservation_set