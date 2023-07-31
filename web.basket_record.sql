
if OBJECT_ID('web.basketLogs') is not null drop table web.basketLogs
if OBJECT_ID('web.basket') is not null drop table web.basket
go

create table web.basket(
	logid int not null identity primary key, 
	custid int not null foreign key references cust.persons (personid), 
	logdate datetime not null default current_timestamp
)
create table web.basketLogs(
	logid int not null foreign key references web.basket (logid), 
	sortCodeId int not null, 
	price money not null, 
	discount dec(3, 2) not null default (0), 
	promoDiscount dec (3,2) not null default (0), 
	customerDiscount dec (3,2) not null default (0),
	qty int not null default (1),
	primary key (logid, sortCodeId)
)

select * from web.basket
select * from web.basketLogs

if OBJECT_ID('web.basket_record') is not null drop proc web.basket_record
go 
create proc web.basket_record 
	@json_data varchar(max),
	@note varchar(max) output
as
set nocount on;
begin try
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
			customerDiscount dec (3,2)
		);

	insert @jsonTable select color, size, styleid, qty, phone, price, discount, promoDiscount, customerDiscount
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
			customerDiscount dec(3,2) '$.customerDiscount'

	) as jsonValues;
		
	select * from @jsonTable;

	insert web.basket (custid) 
	select cust.customer_id(phone)
	from @jsonTable;
	select @logid = SCOPE_IDENTITY() 

	insert web.basketLogs(logid, sortCodeId, price, qty)
	select 
		@logid, 
		inv.barcode_sortid_(j.styleid, j.color, j.size), 
		j.price, j.qty
	from @jsonTable j

	select @note = 'articles have been inserted'
	--throw 50001 , 'debugging', 1
end try
begin catch
	select @note = ERROR_MESSAGE()	
end catch
go


declare @note varchar(max);

DECLARE @json_data NVARCHAR(MAX)
SET @json_data = '{
	"color": "BLUE NAVY", 
	"size": "XXXL", 
	"styleid": "19628", 
	"qty": 1, 
	"phone":"9167834248",
	"price":"29352", 
	"discount": 0.25
	}'

exec web.basket_record 
	@json_data,
	@note output; select @note;

select * from web.basket;
select * from web.basketLogs