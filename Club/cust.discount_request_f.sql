USE fanfan
go

IF OBJECT_ID('inv.barcode_discount_f') IS NOT NULL DROP FUNCTION inv.barcode_discount_f
GO
CREATE FUNCTION inv.barcode_discount_f(@barcodeid INT) RETURNS DECIMAL(3,2) AS BEGIN
	DECLARE @discount DECIMAL(3,2);
		WITH _d (discount, num) AS (
			SELECT 
				P.discount, 
				ROW_NUMBER() OVER (PARTITION BY P.styleID ORDER BY P.pricesetID DESC)
			FROM inv.prices p
				JOIN inv.barcodes b ON b.styleid=P.styleID
			WHERE b.barcodeID = @barcodeid
		)
		SELECT @discount= D.discount
		FROM _d d
		WHERE d.num=1
	RETURN @discount
END
go

IF OBJECT_ID('cust.discount_request_f') IS NOT NULL DROP FUNCTION cust.discount_request_f
GO 
CREATE FUNCTION cust.discount_request_f(@cust_id INT, @just_barcode BIT, @barcodeid INT = 0, @user VARCHAR(25)='') RETURNS VARCHAR(MAX) AS 
BEGIN
	DECLARE @string VARCHAR(MAX);
	IF @just_barcode = 'True'
	BEGIN
		SELECT @string = CONCAT(
			br.brand,
			' ' , se.season, 
			' цена ', 
			FORMAT(inv.barcode_price2(@barcodeid, @user), '#,##0'), 
			'. Cкидка ', 
			format( inv.barcode_discount_f(@barcodeid), '0.0%'), '. ',
			@user, ' запрашивает '
			)
			FROM inv.barcodes b 
				JOIN inv.styles s ON s.styleID=b.styleID
				JOIN inv.brands br ON br.brandID=s.brandID
				JOIN inv.seasons se ON se.seasonID=s.seasonID
			WHERE b.barcodeID=@barcodeid;
    END
	ELSE
	BEGIN
		SELECT @string = CONCAT (
		'клиент ', cdf.customer, ', карта - ', FORMAT(discount/100, '0.0%'), 
		'. ', @user ,
		' запрашивает '
		)
		FROM club.customer_discount_f(@cust_id) cdf
	end
	RETURN @string
END
GO

DECLARE @barcodeid INT = 648700
DECLARE @user VARCHAR(25)= 'Федоров А. Н.';
SELECT cust.discount_request_f(14, 'False', @barcodeid, @user)


SELECT inv.barcode_price2(@barcodeid, @user), FORMAT( inv.barcode_discount_f(@barcodeid), '0.0%');
