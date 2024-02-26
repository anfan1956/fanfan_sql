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
		
		declare @fiscal varchar(1);
		declare @barcodes_count int = (select count(*) from @info);
		declare @saleid int, @returnid int, @customerid int, @accTranId int, @registerid int;	
		declare @contractorid int, @trantypeid int;
		--this table is created for acc.entries to insert
		declare @transactions table (transid int, clientid int, articleid int, pmtForm varchar(25));


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

		select @fiscal = s.fiscal_id
		from inv.sales s where s.saleID = @saleid;

		select distinct @contractorid =  o.vendorID
		from inv.orders o
			join inv.styles s on s.orderID=o.orderID
			join inv.barcodes b on b.styleID=s.styleID
			join @info i on i.barcodeid=b.barcodeID;


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
		insert inv.sales(saleID, customerID, divisionID, salepersonID, fiscal_id)
		select @returnid, @customerid, @divisionid, @userid, @fiscal; 

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
			select sr.saleID, sr.receipttypeID, sr.amount, sr.registerid
			from inv.sales_receipts sr 
				--join inv.sales s on s.saleID=sr.saleID	
			where sr.saleID = @saleid
		)
		, _return as (
			select sr.saleID, sr.receipttypeID, sr.amount, sr.registerid
			from inv.sales_receipts sr 
				--join inv.sales s on s.saleID=sr.saleID	
			where sr.saleID = @returnid
		)
		update r set r.registerid=s.registerid
		from _sale s
			join _return r on s.receipttypeID= r.receipttypeID;
		select @registerid =sr.registerid from inv.sales_receipts sr where sr.saleID=@returnid;


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

		--создаем запись в accounting transactions
		insert acc.transactions(transdate, recorded, bookkeeperid, currencyid, articleid, clientid, amount, comment, document, saleid, barcodeid)
		output inserted.transactionid, inserted.clientid, inserted.articleid, inserted.document into @transactions
		select 
			@date transdate, CURRENT_TIMESTAMP recorded, @userid bookkeeperid, t.currencyid, 
			t.articleid, t.clientid, t.amount, t.comment, t.document, @returnid saleid, t.barcodeid
		from acc.transactions t where t.saleid = @saleid
		select @accTranId = SCOPE_IDENTITY();
--		select * from acc.transactions where transactionid =@accTranId
--		select * from @transactions;

		-- делаем запись в acc.entries
		declare @entries table (entryid int);

		with _seed (is_credit, accountid, contractorid, registerid) as (
			select 'False', acc.account_id ('счета к оплате'), org.contractor_id('E&N suppliers'), null
			union
			select 'True', null, null, @registerid
		)
		, _entries (transactionid, is_credit, accountid, contractorid) as (
		select t.transid, s.is_credit, isnull(s.accountid, a.accountid), isnull(s.contractorid, t.clientid)
		from _seed s
			cross apply @transactions t 
			join acc.articles a on a.articleid=t.articleid
		)
		merge acc.entries as t using _entries s
		on t.transactionid = s.transactionid
		when not matched then 
		insert (transactionid, is_credit, accountid, contractorid)
		values(transactionid, is_credit, accountid, contractorid)
		output inserted.entryid into @entries;

		select e.*, a.account, c.contractor, t.*, ar.article
		from acc.entries e 
			join acc.transactions t on t.transactionid=e.transactionid
			join @entries en on en.entryid=e.entryid
			join acc.accounts a on a.accountid=e.accountid
			join org.contractors c on c.contractorID=e.contractorid
			join acc.articles ar on ar.articleid=t.articleid;

	select @note = '№ возврата - ' + format(@returnid, '0') + '; ' + STRING_AGG(convert(varchar(max), rt.r_type_rus +' - ' + format(sr.amount, '#,##0.00;' ) ),  '; ' ) 
	from inv.sales_receipts sr 
		join fin.receipttypes rt on rt.receipttypeID= sr.receipttypeID
	where sr.saleID= @returnid;
	

--	;throw 50001, @note, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	select @note errorMessage;
	rollback transaction
end catch
go

set nocount on; declare @info inv.sales_cash_type; insert @info values (666706, 110000, 0.3, 77000, 1); 
declare @customerid int = 1, @user varchar (25) = 'ЛАЗАРЕВА Н. В.', @division varchar (25) = '05 УИКЕНД', @customer_discount decimal (4, 3) = 0, @datetime datetime = '20240223', @r int; 
--exec @r = inv.sales_cash_proc_3 @datetime,  @customerid, @user, @division, @customer_discount, @info, 0, 'по телефону:77000:ТИНЬКОФФ', NULL; select @r;