use fanfan
go

if OBJECT_ID ('inv.styleBarcodes_update_') is not null drop proc inv.styleBarcodes_update_
if TYPE_ID('inv.colorSizeQty_type') is not null drop type inv.colorSizeQty_type
create type inv.colorSizeQty_type as table (
	color varchar(max), 
	size varchar(10), 
	qty int
)
go

create proc inv.styleBarcodes_update_  @info inv.colorSizeQty_type readonly, @shop varchar(max), @styleid int output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction
	declare @r int, @clientID int, @orderID int, @transactiontypeID int,  @vendorid int, @cogs money;
	declare @logStateInId int = inv.logstate_id('in-warehouse')	
	declare @logStateOutId int = inv.logstate_id('external')
	-- knowing the style we find the buyer, order, vendor and type of transaction
	select 
		@clientID= o.buyerID, @orderID= o.orderID, @transactiontypeID= T.transactiontypeID, @vendorid=o.vendorID, @cogs = s.cost
	from inv.styles s 
		join inv.orders o on o.orderID=s.orderID 
		join inv.transactions t on t.transactionID=o.orderID
	where s.styleID=@styleID;
--	select @clientID clientid, @orderID orderid, @transactiontypeID transtypeid, @vendorid

	-- delete all the barcodes from inventory for the styleid. We shall insert them later
	delete i from inv.inventory i
		join inv.barcodes b on b.barcodeID=i.barcodeID and b.styleId=@styleID;

	-- now we will have to update (merge) the list of barcodes
;	with
	_barcodes as (
		select 
			barcodeID, b.sizeID, b.colorID,
			row_number() over( partition by sort_barcodeID order by barcodeID ) as number
		from inv.barcodes b
		where b.styleID = @styleID
	), 
	s (styleID, sizeID, colorID, number) as (
		select s.styleID, sz.sizeID, c.colorID, n.i--, row_number() over( partition by sizeID, colorID order by @styleID )
		from @info i 
			join inv.colors c on c.color=i.color and c.orderID=@orderID
			cross apply inv.styles s 
			join inv.sizes sz on sz.sizegridID = s.sizegridID and sz.size=i.size
			join cmn.numbers n on n.i<=qty
		where s.styleID=@styleid
	), 
	src (barcodeid, colorid, sizeid, styleid, cogs ) as (
		select isnull(b.barcodeID, 0), s.colorid, s.sizeID, s.styleID, @cogs
		from s	
			left join _barcodes b 
				on s.number=b.number 
				and b.colorID = s.colorID
				and b.sizeID = s.sizeID
	)
	merge inv.barcodes as t using src
	on t.barcodeid=src.barcodeid
	when not matched then 
		insert (styleid, sizeid, colorid, cogs)
		values (styleid, sizeid, colorid, cogs)
	when not matched by source and t.styleid=@styleid then delete ;

	declare @barcodes table(barcodeid int);
	insert @barcodes select b.barcodeID from inv.barcodes b where b.styleID=@styleid;

	with _logstates (logstateid, opersign, divisionid) as (
		select @logStateOutId , -1, 0 union all select @logStateInId, 1, org.division_id(@shop)
	)
	insert inv.inventory(clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
	select @clientID clientid, l.logstateid, l.divisionid divisionid, @orderID transactionid, opersign, b.barcodeid
	from @barcodes b
		cross apply _logstates l ;
	declare  @rows int;
	select @rows = @@ROWCOUNT/2;
	select @rows rowsInserted


--;	throw 50001, @message, 1
	commit transaction
end try
begin catch
	select ERROR_MESSAGE()

	rollback transaction
end catch
go
		
set nocount on; declare @info inv.colorSizeQty_type, @shop varchar(max) = '05 УИКЕНД', @styleid int =20407;
insert @info (color, size, qty) values 
('BLACK','36', 3), ('BLACK','38', 2), ('BLACK','40', 2), ('BLACK','42', 3), 
('BLUE','36', 1), ('BLUE','38', 2), ('BLUE','40', 2), ('BLUE','42', 2), ('BLUE','44', 1), 
('WHITE','40', 1), ('WHITE','42', 1), ('WHITE','44', 1);
--exec inv.styleBarcodes_update_ @info, @shop, @styleid





