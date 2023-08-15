if OBJECT_ID('web.basket_record') is not null drop proc web.basket_record
go 
create proc web.basket_record 
	@json_data varchar(max),
	@note varchar(max) output
as
set nocount on;
begin try
	begin transaction
		DECLARE 
			@color VARCHAR(50), 
			@size varchar(50), 
			@styleid VARCHAR(50), 
			@qty int, 
			@phone char(10), 
			@price money, 
			@custid int , 
			@logid int, 
			@sortCodeId int

		declare @jsonTable table (
				color VARCHAR(50), 
				size varchar(50), 
				styleid VARCHAR(50), 
				qty int, 
				phone char(10), 
				price money, 
				discount dec(3,2), 
				promoDiscount dec(3,2), 
				customerDiscount dec (3,2), 
				uuid char(36)
			);

		insert @jsonTable select color, size, styleid, qty, phone, price, discount, promoDiscount, customerDiscount, uuid
		from OPENJSON (@json_data)
		with (
				color VARCHAR(50) '$.color', 
				size varchar(50) '$.size', 
				styleid VARCHAR(50) '$.styleid', 
				qty int '$.qty', 
				phone char(10) '$.phone', 
				price money  '$.price', 
				discount dec(3,2) '$.discount', 
				promoDiscount dec(3,2) '$.promoDiscount', 
				customerDiscount dec(3,2) '$.customerDiscount',
				uuid char(36) '$.uuid'

		) as jsonValues;
		
	--	select * from @jsonTable;

		insert web.basket (custid, uuid) 
		select 
			cust.customer_id(phone),		
			uuid
		from @jsonTable;
		select @logid = SCOPE_IDENTITY() 

		insert web.basketLogs(logid, sortCodeId, price, qty, discount, promoDiscount, customerDiscount)
		select 
			@logid, 
			inv.barcode_sortid_(j.styleid, j.color, j.size), 
			j.price, j.qty, discount, promoDiscount, customerDiscount
		from @jsonTable j

		select @note = 'articles have been inserted'
	--throw 50001 , 'debugging', 1
	commit transaction
end try
begin catch	
	select @note = 'error in procedure'  --ERROR_MESSAGE()	
	rollback transaction
end catch
go


--set nocount on; declare @note varchar(max); 
--if @@TRANCOUNT>0 rollback transaction; 
--exec web.basket_record 
------'{"color":" 778 LUNAR ROCK","size":"XXL","styleid":"19585","price":"76500","discount":"0.0","phone":"9167834248","qty":1,"promoDiscount":"0.3"}'
--'{"color":"DEGAS - DEG","size":"2","styleid":"7445","price":"21675","discount":"0.0","phone":"","qty":"","promoDiscount":"0.0","uuid":"43bd92e2-dec2-4f6b-9299-86437e11fead"}'
----'{"color":"ALUMINIUM","size":"2","styleid":"9574","price":"21675","discount":"0.0","phone":"","qty":"","promoDiscount":"0.0","uuid":"16780321-99b9-4bf7-ba5f-3285f2db30c1"}'
--, @note output; select @note;

----declare 
----	@color varchar(max) = '34300 BLACK',
----	@size varchar(max) = 'XXL',
----	@styleid int = 19166
----select inv.barcode_sortid_(@styleid, @color, @size) 

select * from web.basket
select * from web.basketLogs

