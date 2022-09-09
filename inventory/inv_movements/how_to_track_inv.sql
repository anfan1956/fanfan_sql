use fanfan
go

--SELECT * FROM inv.logstates l
/*
barcodes
divisionid
customerid
userid
date
price consigned to customer
settlement date
transactionid

	in order to maintain need to create table, cust.on_account
*/


--if OBJECT_ID('cust.on_account')is not null drop table cust.on_account 

--create table cust.on_account(     
--	customerid int not null constraint fk_account_customer foreign key references cust.persons (personid),
--	transactionid INT NOT NULL constraint fk_account_transaction foreign key references inv.transactions (transactionid), 
--	divisionid int not null constraint fk_account_division foreign key references org.divisions (divisionid),
--	deadline date not null,
--	barcodeid INT NOT NULL constraint fk_account_barcode foreign key references inv.barcodes (barcodeid), 
--	price MONEY NOT null,
--	discount DECIMAL(4,3) not null, 
--	constraint pk_on_account primary key (transactionid, barcodeid)
--)

if OBJECT_ID ('inv.customer_on_account_p') is not null drop proc inv.customer_on_account_p
if type_id('inv.barcode_price_discount_type') is not null drop type inv.barcode_price_discount_type
GO
CREATE type inv.barcode_price_discount_type as table (barcodeid int, price money, discount dec(4,3))
go
create PROC inv.customer_on_account_p  
	@barcodes inv.barcode_price_discount_type READONLY,
	@userid INT, 
	@customerid INT,
	@divisionid int,
	@date date,
	@credit BIT,
	@note varchar (max) output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin TRANSACTION

		DECLARE @transactionid INT, @transactiontypeid int;

-- select type of transaction if the merch is given to customer or taken back from him
		SELECT @transactiontypeid= CASE @credit 
				WHEN 'TRUE' THEN inv.transactiontype_id('CUST_CONSMT')
				ELSE inv.transactiontype_id('CUST_CONSMT_RETURN') END

		DECLARE @opersign INT = 1- 2 * @credit;

-- create new transaction of the above type
		INSERT INV.transactions(transactiontypeID, userID)
		SELECT @transactiontypeid, @userid	
		SELECT @transactionid =  SCOPE_IDENTITY();

-- move inventory to/from the customer account
		WITH _seed (opersign, divisionid) AS 
		(
			SELECT @opersign, NULL UNION ALL
			SELECT -@opersign, org.division_id('НА РУКАХ У КЛИЕНТОВ')
		)
		, fin AS (
		SELECT b.barcodeID, v.logstateID, 
			v.clientID, @transactionid transactionid, 
			s.opersign, ISNULL(s.divisionid, v.divisionID) divisionid
		FROM @barcodes b
		JOIN inv.v_r_inwarehouse v ON v.barcodeID=b.barcodeID
			CROSS APPLY _seed s
		)
		INSERT inv.inventory (barcodeID, logstateID, clientID, transactionid, opersign, divisionid)
		SELECT f.barcodeID, f.logstateID, f.clientID, f.transactionid, f.opersign, f.divisionid
		FROM fin f;

		WITH _prices (barcodeid, price, discount) AS (
				SELECT 
					b.barcodeID, b.price, b.discount
				from @barcodes b	
			)
		INSERT cust.on_account (customerid, transactionid, deadline, barcodeid, price, discount, divisionid)
		SELECT 
			@customerid, @transactionid, @date, p.barcodeid, p.price, p.discount, @divisionid 		
		FROM _prices p;
--		SELECT * FROM cust.on_account oa;

	set @note = 'Записано в транзакции №' + cast(@transactionid as varchar(max)) + ' до '  
		+ format (@date, 'dd.MM.yyyy');
	--throw 50001, @message, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback transaction
end catch
go
		
set nocount on; declare @note varchar (max); 
DECLARE @userid INT = 37, @customerid INT = 12858,  @deadline date = '20220902', @divisionid int = 27; 
DECLARE @barcodes inv.barcode_price_discount_type; 
INSERT @barcodes VALUES 
(658245, 23584, 0), (662471, 13728, 0), (654887, 16544, 0), (648672, 13536, 0), (636841, 19360, 0), (659535, 18656, 0); 
--EXEC inv.customer_on_account_p 
--	@barcodes=@barcodes, 
--	@userid=@userid, 
--	@credit ='True', 
--	@date = @deadline, 
--	@divisionid = @divisionid,
--	@note = @note OUTPUT, 
--	@customerid = @customerid ; 
--select @note


if OBJECT_ID('inv.inventory_on_account_v') is not null drop view inv.inventory_on_account_v
go 
create view inv.inventory_on_account_v as
	select 
		a.customerid ,  
		p.lfmname client,  
		a.transactionid trans_id , 
		dbo.justdate( t.transactiondate) trans_date, 
		cast(a.deadline as datetime) due_date, 
		a.barcodeid, 
		a.price, 
		a.discount, 
		a.price* (1-a.discount) net_price,
		u.username user_name, 
		case tt.transactiontype 
			when 'CUST_CONSMT' then 'выдача'
			when 'CUST_CONSMT_RETURN' then 'возврат' end trans_type,			
		s.article, 
		it.inventorytyperus category, 
		br.brand , 
		sz.size , 
		c.color , d.divisionfullname shop,
		DATEDIFF(dd,t.transactiondate, deadline) days_out

	from cust.on_account a
		join cust.persons p on p.personID = a.customerid
		join inv.transactions t on t.transactionID=a.transactionid
		join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
		join inv.barcodes b on b.barcodeID = a.barcodeid
		join inv.styles s on s.styleID= b.styleID
		join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
		join inv.brands br on br.brandID=s.brandID
		join inv.sizes sz on sz.sizeID=b.sizeID
		join inv.colors c on c.colorID=b.colorID
		join org.users u on u.userID= t.userID
		join org.divisions d on d.divisionID=a.divisionid
go
select * 
from inv.inventory_on_account_v
select 
	customerid, client, trans_id, trans_date, barcodeid
from inv.inventory_on_account_v v


if OBJECT_ID('cust.customer_name_barcodes_f') is not null drop function cust.customer_name_barcodes_f
go 
create function cust.customer_name_barcodes_f(@barcodes barcodes_list readonly) returns table as
return

select distinct c.customerid, cust.customer_fullname(c.customerid) customer, cn.connect phone
from cust.on_account c
	join @barcodes b on b.barcodeID=c.barcodeid
	join cust.connect cn on c.customerid=cn.personID
		where cn.connecttypeID=1 and cn.prim= 'True'
go

declare  @barcodes dbo.barcodes_list
insert @barcodes values (658808), (652166);
select * from cust.customer_name_barcodes_f (@barcodes)
