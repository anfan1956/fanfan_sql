if OBJECT_ID ('web.reservation_json') is not null drop proc web.reservation_json
go 
create proc web.reservation_json @json varchar(max) as
set nocount on; 
begin try
	begin transaction

/*
	0. parse @json, declare parameters
		
		
	1. Check if inventory from is available
		z. the procedure is not working with barcodes
		a. if not - return error message
		b. else  - continue
	2. Create transaction
	3. Create site reservation_set - inv. set, mayb simultaneously with 1
	4. Create site reservation  - add to inv.reservations table
	5. insert resrvation set into inv.inventory
*/
-- 0.
		declare 
			@r int, 
			@reservationid int, @user varchar(max), 
			@userid int, @phone char(10), @wait_minutes int,
			@divisionid int = org.division_id('fanfan.store'),
			@custid int, 
			@date datetime = CURRENT_TIMESTAMP;

			select @userid = personid from org.persons p where p.lfmname =@user;
			select @custid = cust.customer_id(@phone);

		declare
			@expiration datetime = dateadd(MINUTE, @wait_minutes, @date) ;

		--insert inv.transactions (transactiondate, transactiontypeID, userID)
		--values (@date, inv.transactiontype_id('ON_SITE RESERVATION'), @userid);
		--select @reservationid =SCOPE_IDENTITY();

	;throw 50001, 'debuggin', 1
	commit transaction;
end try
begin catch
	select ERROR_MESSAGE() error for json path
	rollback transaction
end catch
go
declare @json varchar(max);
select @json=
'[
{"phone":"9167834248","procName":"ON_SITE RESERVATION","uuid":"bd9d6990-2368-4e4a-9efd-7f158b8dfcaa"},
{"styleid":"13530","color":"WHITE","size":"3","qty":2,"price":19125,"discount":0.0,"promo":0.25,"pieces":2},
{"styleid":"13530","color":"WHITE","size":"4","qty":2,"price":19125,"discount":0.0,"promo":0.25,"pieces":2}
]'



exec web.reservation_json @json


select
	(select 
	'9167834248' phone,
	'ON_SITE RESERVATION' procName, 
	'bd9d6990-2368-4e4a-9efd-7f158b8dfcaa' uuid 
	for json path) nam
union select	
	(select 
	'13530' styleid,
	'WHITE' color,
	'4' size,
	2 qty,
	19125 price, 
	0.0 discount, 
	.25 promo, 
	2 pieces
	for json path)
union select	
	(select 
	'13530' styleid,
	'WHITE' color,
	'3' size,
	2 qty,
	19125 price, 
	0.0 discount, 
	.25 promo, 
	2 pieces
	for json path)
