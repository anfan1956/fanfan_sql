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
	declare @customer varchar(25) = (select customer from club.customer_discount_f(1));

	IF @just_barcode = 'True'
		BEGIN
			SELECT @string = 
				----CONCAT(
				--br.brand +
				--' ' + se.season + 
				--' цена ' + 
				--FORMAT(inv.barcode_price2(@barcodeid, @user), '#,##0')  
				--+ '\nКлиент: ' +  @customer  + ' Cкидка ' + 
				--format( inv.barcode_discount_f(@barcodeid), '0.0%') + '. ' 
				--+ '\nзапрашивает скидку '
				----)
			CONCAT(br.brand, ' ', se.season, ', ', it.inventorytype, ', \nцена:', format(bp.price, '#,##0'), ' \nскидка: ', format (bp.discount, 'P1') , '\n')
			FROM inv.barcodes b 
				JOIN inv.styles s ON s.styleID=b.styleID
				JOIN inv.brands br ON br.brandID=s.brandID
				JOIN inv.seasons se ON se.seasonID=s.seasonID
				join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
				cross apply (select * from inv.barcode_price3 (@barcodeid)) bp
			where b.barcodeID =@barcodeid

			--FROM inv.barcodes b 
			--	JOIN inv.styles s ON s.styleID=b.styleID
			--	JOIN inv.brands br ON br.brandID=s.brandID
			--	JOIN inv.seasons se ON se.seasonID=s.seasonID
			--WHERE b.barcodeID=@barcodeid;
		END
	ELSE
		BEGIN
			SELECT @string = 
			--CONCAT (
			'Клиент: ' + cdf.customer + '\nкарта - ' + FORMAT(cdf.discount/100, '#,##0.0%')
			+  ' запрашивает скидку '
			--)
			FROM club.customer_discount_f(@cust_id) cdf
		end
	RETURN @string
END
go
declare @barcodeid int = 666706, @string varchar(max);
select inv.barcode_discount_f(@barcodeid)
SELECT cust.discount_request_f(1, 'True', @barcodeid, 'ФЕДОРОВ А. Н.')

select @string = CONCAT(br.brand, ' ', se.season, ', ', it.inventorytype, ', \nцена:', bp.price, ', скидка: ', bp.discount , '\n')
			FROM inv.barcodes b 
				JOIN inv.styles s ON s.styleID=b.styleID
				JOIN inv.brands br ON br.brandID=s.brandID
				JOIN inv.seasons se ON se.seasonID=s.seasonID
				join inv.inventorytypes it on it.inventorytypeID=s.inventorytypeID
				cross apply (select * from inv.barcode_price3 (@barcodeid)) bp
			where b.barcodeID =@barcodeid

select @string

