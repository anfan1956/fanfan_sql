USE fanfan
GO

IF OBJECT_ID('inv.brands_in_shop_f') IS NOT NULL DROP FUNCTION inv.brands_in_shop_f
GO
CREATE FUNCTION inv.brands_in_shop_f (@divisionfull VARCHAR(50))
RETURNS TABLE AS RETURN
WITH _prices (styleID, discount, num)  as (
	SELECT P.styleID, p.discount, ROW_NUMBER() OVER(PARTITION BY p.styleID ORDER BY p.pricesetID desc)
	FROM inv.prices p 
		JOIN inv.pricesets p1 on p1.pricesetID= P.pricesetID
)
, _current_prices (styleID, discount) AS (
	SELECT p.styleID, p.discount FROM _prices p 
	WHERE p.num=1
	)
SELECT 
	br.brandID, br.brand, s.seasonID, se.season, s.styleID, s.article,
	i.inventorytyperus category, 
	s.cost * r.markup * r.rate price, 
	cp.discount
FROM inv.v_r_inwarehouse v
	JOIN inv.barcodes b ON b.barcodeID=v.barcodeID
	JOIN inv.styles s ON s.styleID=b.styleID
	JOIN inv.orders o ON o.orderID=s.orderID
	JOIN inv.brands br ON br.brandID=s.brandID
	JOIN org.divisions d ON d.divisionID= v.divisionID
	JOIN inv.seasons se ON se.seasonID=s.seasonID
	JOIN inv.inventorytypes i ON i.inventorytypeID= s.inventorytypeID
	JOIN _current_prices cp ON cp.styleID=s.styleID
	JOIN inv.current_rate_v r ON r.divisionid= d.divisionID
							AND r.currencyid= o.currencyID

WHERE D.divisionfullname =  @divisionfull
go

DECLARE @division VARCHAR(25) = '07 ФАНФАН'
--SELECT DISTINCT season, styleid, article, category, price, discount FROM inv.brands_in_shop_f(@division) b WHERE b.brandid= 144

if OBJECT_ID ('inv.discounts_record_p') is not null drop proc inv.discounts_record_p
IF TYPE_ID('inv.barcodes_discounts_type') IS NOT NULL DROP TYPE inv.barcodes_discounts_type
GO
CREATE TYPE inv.barcodes_discounts_type AS TABLE (
	styleid INT, 
	discount money
)
go

create PROC inv.discounts_record_p 
	@info inv.barcodes_discounts_type READONLY,  
	@shop VARCHAR(25) , 
	@person VARCHAR(50),
	@note varchar (max) output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin TRANSACTION
		DECLARE @userID INT = (SELECT p.personID FROM org.persons p WHERE p.lfmname= @person);
		DECLARE @pricesetid INT, @rows int;
		INSERT inv.pricesets (pricetypeID, pricesetdate, userID, comment)
		SELECT inv.pricetype_id('SALE'), CURRENT_TIMESTAMP, @userID, 'sale discounts'
		SET @pricesetid = SCOPE_IDENTITY();

		WITH _prices (styleid, price, discount, num) AS (
			SELECT i.styleid, P.price, i.discount, 
				ROW_NUMBER() OVER(PARTITION BY i.styleID ORDER BY P.pricesetID desc )
			FROM inv.prices p 
				JOIN @info i ON i.styleid=p.styleID
		)
		INSERT inv.prices (pricesetID, styleID, price, discount)
		SELECT @pricesetid, P.styleid, P.price, P.discount
		FROM _prices p
		WHERE p.num = 1;
	
		SELECT @rows = @@rowcount;
		set @note = 'добавлена скидка на ' + CONVERT(VARCHAR(10), @rows) + ' артикулов'

--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback transaction
end catch
go
	
set nocount on; 
declare @info inv.barcodes_discounts_type, @note varchar(max); 
declare @shop varchar(25) = '07 ФАНФАН', @person VARCHAR (50) = 'ФЕДОРОВ А. Н.'; 
insert @info values 
(19365, 0), (19366, 0), (19367, 0), (13837, 0), (18323, 0), (18324, 0), 
(19601, 0), (19602, 0), (19603, 0), (19604, 0), (19614, 0), (19615, 0), 
(19616, 0), (19617, 0), (19619, 0), (19621, 0), (19622, 0), (19623, 0); 
--exec inv.discounts_record_p @info, @shop, @person, @note output; select @note;
--SELECT * FROM @info
--SELECT * FROM inv.pricesets p  ORDER BY 1 desc
--SELECT inv.pricetype_id('SALE')

IF OBJECT_ID('inv.brands_shop_short_f') IS NOT NULL DROP FUNCTION inv.brands_shop_short_f
GO
CREATE FUNCTION inv.brands_shop_short_f (@shop VARCHAR (25)) RETURNS TABLE
AS RETURN
	SELECT DISTINCT br.brandID, br.brand 
	FROM inv.v_r_inwarehouse v
		JOIN inv.barcodes b ON b.barcodeID=v.barcodeID
		JOIN inv.styles s ON s.styleID = b.styleID
		JOIN inv.brands br ON br.brandID= s.brandID
		JOIN org.divisions d ON D.divisionID= v.divisionID
	WHERE D.divisionfullname = @shop
GO
SELECT b.brand, b.brandid FROM inv.brands_shop_short_f('07 ФАНФАН') b
