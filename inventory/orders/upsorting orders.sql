/*
	inv.order_articles_f(@orderid)
	inv.order_colors_f(@orderid)
	inv.styleid_sizes_f(@styleid)
	inv.order_resort_p @syleid int, @colorid int, @sizeid int, @qty int, @note varchar(max) output
	inv.order_re_sorted_drop_f @orderid int, @note varchar(max) output
	inv.re_sorted_article_comp_f(@stlyleid)
	inv.order_re_sorted_drop_f @orderid, @note output
	inv.order_re_sort_update_p @info, @styleid, @note output   -  find very good solution for recursive query to set up billet for barcodes

Задача - дозаказ пересортицы, чтобы были баркоды, стояли цены и т.д.
Дозаказ только в случае, если этот артикул уже есть в заказе.
сначала создаем функцию перечисляющую все артикулы
*/


if OBJECT_ID('inv.order_articles_f') is not null drop function inv.order_articles_f
go 
create function inv.order_articles_f (@orderid int) returns table as return
	with _b (barcodeid) as (
	select b.barcodeID 
	from inv.barcodes b
		join inv.styles s on s.styleID = b.styleID
	where s.orderID = @orderid
	)
	, _resort_barcodes as (
		select distinct i.barcodeID
		from inv.inventory i
		where i.transactionID = @orderid and i.logstateID = inv.logstate_id('RE_SORTED')
	)
	, _orig_barcodes as (
		select * from _b except select * from _resort_barcodes
	)
	, _or (styleid, article, category, cost, sizegrid, comment, pieces, total) as (
		select 
			s.styleid, s.article, t.inventorytyperus, 
			s.cost, sg.sgShort, s.comment,
			sum (i.opersign), 
			sum(s.cost)
		from inv.inventory i
			join _orig_barcodes b on b.barcodeid=i.barcodeID
			join inv.barcodes bc on bc.barcodeID=b.barcodeid
			join inv.styles s on s.styleID=bc.styleID
			join inv.inventorytypes t on t.inventorytypeID=s.inventorytypeID
			join inv.sizegrids sg on sg.sizegridID=s.sizegridID
			left join _resort_barcodes rb on rb.barcodeid=i.barcodeID
		where i.opersign = 1 and i.transactionID=@orderid
		group by s.styleID, s.article, 
			t.inventorytyperus, s.cost, sg.sgShort, s.comment
	)
	, _re (styleid, article, category, cost, sizegrid, comment, pieces, total) as (
		select 
			s.styleid, s.article, t.inventorytyperus, 
			s.cost, sg.sgShort, s.comment,
			sum (i.opersign), 
			sum(s.cost)
		from inv.inventory i
			join _resort_barcodes b on b.barcodeid=i.barcodeID
			join inv.barcodes bc on bc.barcodeID=b.barcodeid
			join inv.styles s on s.styleID=bc.styleID
			join inv.inventorytypes t on t.inventorytypeID=s.inventorytypeID
			join inv.sizegrids sg on sg.sizegridID=s.sizegridID
		where i.opersign = 1 and i.transactionID=@orderid
		group by s.styleID, s.article, 
			t.inventorytyperus, s.cost, sg.sgShort, s.comment
	)
	select o.*, r.pieces re_sorted 
	from _or o
	left join _re r on r.styleid=o.styleid
go


if OBJECT_ID('inv.order_colors_f') is not null drop function inv.order_colors_f
go 
create function	inv.order_colors_f (@orderid int) returns table as return
	with _b (barcodeid) as (
	select b.barcodeID 
	from inv.barcodes b
		join inv.styles s on s.styleID = b.styleID
	where s.orderID = @orderid
	)
	select distinct c.color, c.colorID from _b b
	join inv.barcodes bc on bc.barcodeID= b.barcodeid
	join inv.colors c on c.colorID = bc.colorID
go


if OBJECT_ID ('inv.styleid_sizes_f') is not null drop function inv.styleid_sizes_f
go
create function inv.styleid_sizes_f(@styleid int) returns table as return
select size, sizeID 
from inv.styles s
	join inv.sizes sz on sz.sizegridID= s.sizegridID
where s.styleID = @styleid
go


if OBJECT_ID ('inv.order_resort_p') is not null drop proc inv.order_resort_p 
go
create proc inv.order_resort_p @styleid int, @colorid int, @sizeid int, @qty int, @note varchar(max) output as
set nocount on;
begin try
	begin transaction;

	declare @i int = @qty;
	declare @resortedid int = inv.logstate_id('RE_SORTED'), @orderedid  int = inv.logstate_id('ORDERED')
	declare @barcodes table(styleid int, sizeid int, colorid int);
	declare @just_barcodes table(barcodeid int);
	declare @orderid int = (select orderid from inv.styles s where s.styleID = @styleid)
	declare @clientid int = (select o.buyerID from inv.orders o where o.orderID= @orderid);
	declare @divisionid int = org.division_id('В ПУТИ')

	--creating  billet  - number of rows for the identity generation in table inv.barcodes
	while @i > 0
		begin
			insert @barcodes(styleid, sizeid, colorid) select @styleid, @sizeid, @colorid
			set @i -=  1;
		end 

	-- creating actual records in inv.barcodes table
	insert inv.barcodes (styleid, sizeid, colorid)
	output inserted.barcodeid into @just_barcodes 
	select styleid, sizeid, colorid from @barcodes;
	
	with _logstates(logstateid, opersign) as 
		(select @resortedid, -1 union all select @orderedid, 1)
	, s (clientid, logstateid, divisionid, transactionid, opersign, barcodeid) as (
		select @clientid, l.logstateid, @divisionid, @orderid, l.opersign, b.barcodeid 
		from @just_barcodes b
			cross apply _logstates l)
	insert inv.inventory (clientid, logstateid, divisionid, transactionid, opersign, barcodeid)
	select clientid, logstateid, divisionid, transactionid, opersign, barcodeid from s;

	select @note = 'number of barcodes created: ' + cast ((select count (*) from @just_barcodes ) as varchar(max)) 
	--;throw 50001, 'debugging', 1;
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch
go


if OBJECT_ID('inv.order_re_sorted_drop_f') is not null drop proc inv.order_re_sorted_drop_f
go
create proc inv.order_re_sorted_drop_f @orderid int, @note varchar(max) output as

--just showing how it works
set nocount on;
begin try
	begin transaction;
		declare @barcodes table (barcodeid int);
			with _resort_barcodes as (
		select distinct i.barcodeID
		from inv.inventory i
		where i.transactionID = @orderid and i.logstateID = inv.logstate_id('RE_SORTED')
)
insert @barcodes (barcodeid) select barcodeid from _resort_barcodes;

delete i from @barcodes b
	join inv.inventory i on i.barcodeID = b.barcodeid;

delete i from @barcodes b
	join inv.barcodes i on i.barcodeID = b.barcodeid;

	set @note = 're_sorted deleted'
	--;throw 50001, 'debugging', 1;
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch
go


if OBJECT_ID('inv.re_sorted_article_comp_f') is not null drop function inv.re_sorted_article_comp_f
go
create function inv.re_sorted_article_comp_f (@styleid int ) returns table as return
	with _b (barcodeid, styleid, sizeid, colorid, article, orderid, gridid) as (
		select i.barcodeid, b.styleID, b.sizeID, b.colorID, s.article, s.orderID, s.sizegridID
		from inv.inventory i 
			join inv.barcodes b on b.barcodeid= i.barcodeid
			join inv.styles s on s.styleid= b.styleid
		where s.styleid = @styleid and i.logstateid = inv.logstate_id('RE_SORTED')
	)
	select b.barcodeid, b.styleid, sz.size, c.color, b.article, b.orderid, br.brand, b.gridid
	from _b b
		join inv.sizes sz on sz.sizeID=b.sizeid
		join inv.colors c on c.colorID=b.colorid
		join inv.orders o on o.orderID=b.orderid
		join inv.brands br on br.brandID=o.brandID
go


if OBJECT_ID('inv.order_re_sort_update_p') is not null drop proc inv.order_re_sort_update_p
go
create proc  inv.order_re_sort_update_p @info fan.varvarint_type readonly, @styleid int, @note varchar(max) output as
set nocount on;
begin try
	begin transaction;

	declare @resortedid int = inv.logstate_id('RE_SORTED'), @orderedid  int = inv.logstate_id('ORDERED')
	declare @barcodes table(styleid int, sizeid int, colorid int);
	declare @just_barcodes table(barcodeid int);
	declare @orderid int = (select orderid from inv.styles s where s.styleID = @styleid)
	declare @clientid int = (select o.buyerID from inv.orders o where o.orderID= @orderid);
	declare @divisionid int = org.division_id('В ПУТИ')

	exec inv.order_re_sorted_drop_f @orderid, @note output; 
	if @note <> 're_sorted deleted' 
		throw 50001, 'failed to clear current barcodes', 1; 
	
	with s (n, color, size) as(
		select  1,  i.var1, i.var2
		from @info i
		union all 
		select n + 1, i.var1, i.var2 
		from  s 
		join @info i on i.var1= s.color and i.var2=s.size
		where n < value
	)
	insert inv.barcodes (styleid, sizeid, colorid)
	output inserted.barcodeid into @just_barcodes 
	select st.styleID, sz.sizeID, c.colorID from s
		join inv.colors c on c.color =s.color
		join inv.styles st on st.styleid=@styleid and c.orderID =st.orderID
		join inv.sizes sz on sz.size= s.size and sz.sizegridID=st.sizegridID;
	
	with _logstates(logstateid, opersign) as (select @resortedid, -1 union all select @orderedid, 1)
	, s (clientid, logstateid, divisionid, transactionid, opersign, barcodeid) as (
		select @clientid, l.logstateid, @divisionid, @orderid, l.opersign, b.barcodeid 
		from @just_barcodes b
		cross apply _logstates l
	)
	insert inv.inventory (clientid, logstateid, divisionid, transactionid, opersign, barcodeid)
	select clientid, logstateid, divisionid, transactionid, opersign, barcodeid from s;

	select @note = 'number of barcodes created: ' + cast ((select count (*) from @just_barcodes ) as varchar(max)) 
--	;throw 50001, 'debugging', 1;
	commit transaction
end try
begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch
go
