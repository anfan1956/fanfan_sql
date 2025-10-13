CREATE or alter FUNCTION inv.qrCodeExists (@qr NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
(
    SELECT CASE 
        WHEN EXISTS (
            SELECT 1
            FROM inv.barcodes b
            WHERE b.mark_code = @qr
        )
        THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS ExistsFlag
);

go

declare @qr varchar (83) ='nmlkdfs79b'
