if OBJECT_ID('web.basket_record') is not null drop proc web.basket_record
go 
create proc web.basket_record 
	@json_data varchar(max),
	@note varchar(max) output
as
set nocount on;
begin try
	begin transaction
		DECLARE @logid int
		
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

		declare @this_max int;
		select @this_max =  COUNT(barcodeid) from inv.parent_sortcodes_JSON(@json_data)
--		select @this_max;


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
		

		insert web.basket (custid, uuid) 
		select 
			cust.customer_id(phone),		
			uuid
		from @jsonTable;
		select @logid = SCOPE_IDENTITY() 


		insert web.basketLogs(logid, parent_styleid, qty,  color, size)
		select 
			@logid, 
			j.styleid, 
			j.qty, 
			j.color, j.size		
		from @jsonTable j
		
		declare @qty int, @this int;
		
		select @qty = sum (l.qty) 
			from web.basketLogs l 
			join web.basket b on b.logid=l.logid 
			cross apply @jsonTable j
			where b.custid=cust.customer_id(j.phone)
--		select @qty;

		declare @parent_styleid int = (select j.styleid from @jsonTable j);

		select @this = inv.parentID_in_basket_JSON(@json_data)
--		select @this

		select @note =  (select @this this, @this_max maximum, @qty total for json path)
		
		if (@this >@this_max) 
		begin
			select @note = 'превышено допустимое количество' ;
			throw 50001, @note, 1
		end 

	commit transaction
end try
begin catch	
	select @note = (select ERROR_MESSAGE() error for json path)
	rollback transaction
end catch
go




declare @myStr varchar(max) = 
'{"color":"WHITE","size":"1","styleid":"13530","price":"19125","discount":"0.0","phone":"9167834248","qty":"1","promoDiscount":"0.0","uuid":"6a048147-3384-4a23-8185-7702c610860d"}'
--'{"color":"PLATOON","size":"2","styleid":"13530","price":"19125","discount":"0.0","phone":"9167834248","qty":"1","promoDiscount":"0.0","uuid":"6a048147-3384-4a23-8185-7702c610860d"}'
--'{"color":"WHITE","size":"4","styleid":"13530","price":"19125","discount":"0.0","phone":"9167834248","qty":"1","promoDiscount":"0.0","uuid":"6a048147-3384-4a23-8185-7702c610860d"}'
set nocount on; declare @note varchar(max); 
if @@TRANCOUNT>0 rollback transaction; 
--exec web.basket_record @myStr , @note output; select @note;
--select COUNT(barcodeid) from inv.parent_sortcodes_JSON(@myStr)
--select inv.parentID_in_basket_JSON(@myStr)
--select sum(qty) from web.customer_basket_('9167834248')


select inv.parentID_in_basket_JSON('{"color":"WHITE","size":"3","styleid":"13530","price":"19125","discount":"0.0","phone":"9167834248","qty":"1","promoDiscount":"0.0","uuid":"6a048147-3384-4a23-8185-7702c610860d"}')


--declare 
--	@color varchar(max) = '34300 BLACK',
--	@size varchar(max) = 'XXL',
--	@styleid int = 19166
--select inv.barcode_sortid_(@styleid, @color, @size) 

--select * from web.basket
--select * from web.basketLogs
--select len(color), * 
--from web.basketLogs

