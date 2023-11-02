if OBJECT_ID('inv.inventory_checked_total_') is not null drop function inv.inventory_checked_total_
go
create function inv.inventory_checked_total_ (@shop varchar(max)) returns table as return

	with _b as (
		select 
			v.barcodeID
		from inv.barcodes_location_v v
		where v.divisionID = org.division_id(@shop)	
	)
	, _total (total) as (select count(*) from _b)
	, _checked_all (barcodeid, num) as (
	select b.barcodeID,  ROW_NUMBER() over (partition by b.barcodeid order by i.transactionid desc)
	from _b b
		join inv.inventory i on i.barcodeID = b.barcodeID
		join inv.transactions t on t.transactionID=i.transactionID	
		join inv.inventorytakes it on it.inventorytakeID=i.transactionID
		where it.closed =1
	)
	, _checked_last (checked) as (
		select count(a.barcodeid)
		from _checked_all a
		where a.num=1
	)

	select l.checked, t.total 
	from _checked_last l
	cross apply _total t
go
declare @shop varchar (max) = '07 ФАНФАН'

select checked, total from inv.inventory_checked_total_(@shop)