use fanfan
go

if OBJECT_ID ('inv.return_all_receipts_p') is not null drop proc inv.return_all_receipts_p
go

-- normal return: all the returns  are posted at runtime time.
-- if for technical reasons returns are not posted intime, date of actual return must be provided

create proc inv.return_all_receipts_p
	@info inv.barcode_type readonly,
	@userid int,
	@date datetime, 
	@divisionid int,
	@note varchar (max) output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction
		
		declare @barcodes_count int = (select count(*) from @info);
		declare @saleid int, @returnid int, @customerid int;	

		with _s as (
			select i.*, ROW_NUMBER() over(partition by transactionid order by f.barcodeid) num
			from inv.inventory i 
				join @info f on f.barcodeid= i.barcodeID
			where i.logstateID = inv.logstate_id('SOLD')
		)
		select top 1 @saleid = transactionID 
		from _s s where s.num=@barcodes_count
		order by transactionid desc;

		if @saleid is null 
			begin
				select @note = 'выбранные баркоды относятся к разным по номеру операциям';
				throw 50001, @note, 1
			end 

		select @customerid = customerid from inv.sales where saleID= @saleid;
			
		declare @amount money = (select sum(sg.amount)
		from inv.sales_goods sg
			join @info b on b.barcodeid=sg.barcodeID
			 where sg.saleID= @saleid )


		insert inv.transactions (transactiondate, transactiontypeID, userID)
		select @date, inv.transactiontype_id ('RETURN'), @userid;
		select @returnid =SCOPE_IDENTITY();


		insert inv.sales(saleID, customerID, divisionID, salepersonID)
		select @returnid, @customerid, @divisionid, @userid; 


		with s as (
			select r.receipttypeID, 
				s.amount, 
				rank() over (order by rec_rank) net_rank 	
			from  inv.sales_receipts s
				join fin.receipttypes r on r.receipttypeID=s.receipttypeID
			where s.saleID = @saleid 
		)
		, t as (
			select receipttypeID, 
			amount, 
			net_rank , 
			case net_rank 
				when 1 then iif(@amount>amount, amount, @amount) 
				else amount end prim
			from s
		)
		insert inv.sales_receipts (saleID, receipttypeID, amount)
		select 
			@returnid,
			receipttypeID,  
			isnull(@amount - lag(prim) over(order by net_rank), prim) amount
		from t;


		insert inv.sales_goods(saleID, barcodeID, amount, price, client_discount, barcode_discount)
		select @returnid, g.barcodeID, -g.amount, g.price, g.client_discount, g.barcode_discount 
		from inv.sales_goods g
			join @info i on i.barcodeid = g.barcodeID
		where g.saleID= @saleid;

		with _seed (logstateid, divisionid, opersign) as (
			select inv.logstate_id('SOLD'), null, -1 
			union 
			select inv.logstate_id('IN-WAREHOUSE'), @divisionid, 1
			)
		--insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
		select 
			i.clientID, 
			s.logstateID,
			isnull (s.divisionID, i.divisionid),
			i.transactionID,
			s.opersign, 
			i.barcodeID
		from inv.inventory i 
			join @info f on f.barcodeid= i.barcodeID
			cross apply _seed s
		where i.transactionID = @saleid and i.logstateID = inv.logstate_id('SOLD');

		exec cust.totals_update;		


	set @note = ''
	;throw 50001, @message, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback transaction
end catch
go


set nocount on; 
declare @note varchar (max), @saleid int, @userid int= 1;
declare @divisionid int = 27;
declare @date datetime = getdate();
declare @info inv.barcode_type; insert @info values (643080), (651042), (651942)--, (659992)

exec inv.return_all_receipts_p
	@info = @info,
	@userid = @userid,
	@date = @date,
	@divisionid = @divisionid,
	@note = @note output; 
select @note
