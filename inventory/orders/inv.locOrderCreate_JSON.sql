use fanfan
go

if OBJECT_ID ('inv.locOrderCreate_JSON') is not null drop proc inv.locOrderCreate_JSON
go

create proc inv.locOrderCreate_JSON @json varchar (max) output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin transaction

-- Declare the mapping table
DECLARE @fieldMapping TABLE (
    RussianFieldName VARCHAR(MAX),
    EnglishFieldName VARCHAR(MAX)
);

-- Insert the mappings
INSERT INTO @fieldMapping (RussianFieldName, EnglishFieldName)
VALUES 
    ('Дата', 'Date'),
    ('Поставщик', 'Supplier'),
    ('Шоурум', 'Showroom'),
    ('Магазин', 'Shop'),
    ('Сезон', 'Season'),
    ('Валюта', 'Currency'),
    ('Тип заказа', 'Order Class'),
    ('Наценка', 'Markup'),
    ('Заказ №', 'Order Number'),
    ('Количество, шт', 'Quantity'),
    ('Сумма', 'Sum'),
    ('Оператор', 'Operator');

-- Declare the header table
DECLARE @header TABLE (
    Field VARCHAR(MAX),
    Value VARCHAR(MAX)
);

-- Parse the JSON data and insert into the header table
;WITH s (RussianField, Value) AS (
    SELECT 
        field, 
        value 
    FROM 
        OPENJSON(@json)
        WITH (
            field VARCHAR(MAX) '$.fields',
            value VARCHAR(MAX) '$.value'
        ) AS jsonValue    
)
INSERT INTO @header (Field, Value)
SELECT 
    fm.EnglishFieldName, 
    s.Value 
FROM 
    s
INNER JOIN 
    @fieldMapping fm ON s.RussianField = fm.RussianFieldName;

-- Display the header table
--SELECT * FROM @header;
declare @date datetime = (select  CONVERT(date, h.value, 104) from @header h where h.Field = 'Date')
declare @buyerid int= (select d.clientID from @header h 
	join org.divisions d on d.divisionfullname=h.Value
	where h.Field = 'Shop')
declare @vendorid int = (select c.contractorID from @header h 
	join org.contractors c on c.contractor=h.Value
	where h.Field = 'Supplier')
declare @showroomid int = (select c.contractorID from @header h 
	join org.contractors c on c.contractor=h.Value
	where h.Field = 'Showroom')
declare @seasonid int = (select c.seasonID from @header h 
	join inv.seasons c on c.season=h.Value
	where h.Field = 'Season')
	select @seasonid seasonid;
declare @userid int = (select p.personID from @header h 
	join org.persons p on p.lfmname=h.Value
	where h.Field = 'Operator')
declare @currencyid int= (select cr.currencyID from @header h 
	join cmn.currencies cr on cr.currencycode=h.Value
	where h.Field = 'Currency')
declare @orderclassid int  = (select oc.orderclassid from @header h
	join inv.orderclasses oc on oc.orderclassRus= h.Value 
	where h.Field = 'Order Class'
	)
declare @transtypeid int=(select case h.value
	when 'КОНСИГНАЦИЯ' then inv.transactiontype_id('Consignment')
	else inv.transactiontype_id('Order')
	end 
	from @header h where h.Field = 'Order Class')
	
declare @markup money = (select Value from @header h where h.Field = 'Markup')
/*
select	
	@date transactionidate, 
	@buyerid buyerid, 
	@vendorid vendorid, 
	@currencyid currencyid, 
	@markup markup, 
	@transtypeid transtypeid, 
	@userid userid
*/

--create new transaction
declare @transid int ;
insert inv.transactions(transactiondate, transactiontypeID, userID)
select @date, @transtypeid, @userid
select @transid = SCOPE_IDENTITY()
--select * from inv.transactions where transactionID= @transid

--create new order
insert inv.orders (orderid, orderclassID, buyerID, vendorID, showroomID, seasonID, currencyID, markup, deliverydate)
select @transid, @orderclassid, @buyerid, @vendorid, @showroomid, @seasonid, @currencyid, @markup, @date
--select * from inv.orders o where o.orderID = @transid

		select @message = 'создан заказ ' + cast( @transid as varchar(max)) 
		select @message  success, @transid orderid, h.Value Тип  from @header h where h.Field = 'Order Class'  for json path;				


	
--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
		select  ERROR_MESSAGE() error for json path
	rollback transaction
end catch
go
		

