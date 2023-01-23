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

-- если эти баркоды были проданы неоднократно, находим последнюю операцию (top 1) где участвовали
-- все баркоды и операция - не возврат	
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
		else if (select t.transactiontypeID from inv.transactions t where t.transactionID = @saleid) = inv.transactiontype_id('return')
			begin
				select @note = 'последняя операция - возврат. Повторный возврат невозможен';
				throw 50001, @note, 1
			end 

		select @customerid = customerid from inv.sales where saleID= @saleid;
			
-- вычисляем полную сумму к возврату
		declare @amount money = (select sum(sg.amount)
		from inv.sales_goods sg
			join @info b on b.barcodeid=sg.barcodeID
			 where sg.saleID= @saleid )

-- создаем транзакцию "возврат"
		insert inv.transactions (transactiondate, transactiontypeID, userID)
		select @date, inv.transactiontype_id ('RETURN'), @userid;
		select @returnid =SCOPE_IDENTITY();

-- создаем продажу
		insert inv.sales(saleID, customerID, divisionID, salepersonID)
		select @returnid, @customerid, @divisionid, @userid; 

-- создаем чеки возврата в соответствии с тем, как была произведена оплата
-- в случае смешанной оплаты сначала возвращаем на кредитку, потом наличку
-- добавил регистр
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

-- делаем обновление регистров возврата по начальной продаже
		with _sale as (
			select sr.*
			from inv.sales_receipts sr 
				join inv.sales s on s.saleID=sr.saleID	
			where s.saleID = @saleid
		)
		, _return as (
			select sr.*
			from inv.sales_receipts sr 
				join inv.sales s on s.saleID=sr.saleID	
			where s.saleID = @returnid
		)
		update r set r.registerid=s.registerid
		from _sale s
			join _return r on s.receipttypeID= r.receipttypeID
		;

-- записываем  в  inv.sales_goods с обратным знаком
		insert inv.sales_goods(saleID, barcodeID, amount, price, client_discount, barcode_discount)
		select @returnid, g.barcodeID, -g.amount, g.price, g.client_discount, g.barcode_discount 
		from inv.sales_goods g
			join @info i on i.barcodeid = g.barcodeID
		where g.saleID= @saleid;

-- делаем запись в inv.inventory		
		with _seed (logstateid, divisionid, opersign) as (
			select inv.logstate_id('SOLD'), null, -1 
			union 
			select inv.logstate_id('IN-WAREHOUSE'), @divisionid, 1
			)
		insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
		select 
			i.clientID, 
			s.logstateID,
			isnull (s.divisionID, i.divisionid),
			@returnid,
			s.opersign, 
			i.barcodeID
		from inv.inventory i 
			join @info f on f.barcodeid= i.barcodeID
				cross apply _seed s
		where 
			i.transactionID = @saleid 
			and i.logstateID = inv.logstate_id('SOLD');

	select @note = '№ возврата - ' + format(@returnid, '0') + '; ' + STRING_AGG(convert(varchar(max), rt.r_type_rus +' - ' + format(sr.amount, '#,##0.00;' ) ),  '; ' ) 
	from inv.sales_receipts sr 
		join fin.receipttypes rt on rt.receipttypeID= sr.receipttypeID
	where sr.saleID= @returnid;
	--;throw 50001, @note, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback transaction
end catch
go
