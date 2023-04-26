declare 
	@info web.reservation_type; 
insert @info values 
	(658777, 29325, 0, 0.12, 25806), 
	(652306, 40800, 0, 0.12, 35904), 
	(651524, 31896.25, 0, 0.12, 28068.7); 

select * from inv.site_reservation_set
select * from inv.inventory i where i.transactionID = 77204


select i.barcodeid, sum(iv.opersign) 
from @info i
join inv.inventory iv on iv.barcodeID= i.barcodeid
where iv.logstateID = inv.logstate_id ('in-warehouse')
group by i.barcodeid
having sum(iv.opersign)>0

if OBJECT_ID('web.reservations_clear') is not null drop  proc web.reservations_clear
go
create proc web.reservations_clear as

declare @transactions table(transactionid int);

insert @transactions
select t.transactionID 
from inv.transactions t 
where t.transactiontypeID in (32, 33) ;
declare @n int = (select count(*) from @transactions);
--select t.transactionid, ROW_NUMBER() over(order by transactionid)  num from @transactions t;

declare @transid int
declare @i int=1
while @i<=@n
begin;
	with t (transactionid, num) as (
		select t.transactionid, ROW_NUMBER() over(order by transactionid)  num
		from @transactions t
	)
	select @transid = transactionid
	from t  where num = @i;
	exec inv.transaction_delete @transid
	--select @transid
	select @i=@i+1;
end

go

select t.transactionID 
from inv.transactions t 
where t.transactiontypeID in (32, 33) 

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