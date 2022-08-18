


IF OBJECT_ID('sms.promo_discount_f') IS NOT NULL DROP FUNCTION sms.promo_discount_f
GO 
CREATE FUNCTION sms.promo_discount_f (@promocode VARCHAR(6), @cust_id INT) RETURNS DECIMAL(4, 3) AS 
BEGIN

	DECLARE @discount DECIMAL(4,3); 
	WITH _discount AS (
	SELECT i.discount, i.smsid
	FROM sms.instances i
		JOIN sms.instances_customers ic ON ic.smsid=i.smsid
	WHERE i.expirationDate>=dbo.justdate(getdate()) 
		AND ic.customerid = @cust_id
		AND ic.promocode = @promocode

	)
	SELECT TOP 1 @discount = discount
		FROM _discount ORDER BY smsid desc
	SELECT @discount= ISNULL(@discount, 0);
	RETURN @discount;
END
GO

DECLARE @promocode VARCHAR(6) = '3114', @cust_id INT = 4;
SELECT sms.promo_discount_f(@promocode, @cust_id)

SELECT * FROM sms.instances i
SELECT *FROM sms.instances_customers ic