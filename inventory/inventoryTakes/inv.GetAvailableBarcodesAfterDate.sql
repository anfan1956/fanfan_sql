CREATE OR ALTER FUNCTION inv.GetAvailableBarcodesAfterDate
(
    @startDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT ai.barcodeid
    FROM (
        -- Active Inventory: Barcodes from inventory takes after the given date
        SELECT DISTINCT
            i.barcodeid
        FROM inv.invTake_barcodes i
        JOIN inv.transactions t ON t.transactionID = i.takeID
        WHERE t.transactiondate >= @startDate
    ) ai
    OUTER APPLY (
        -- Net Sales Calculation: Calculate sales and returns for each barcode
        SELECT 
            SUM(CASE WHEN tt.transactiontype = 'Sale' THEN 1 ELSE 0 END) AS SaleCount,
            SUM(CASE WHEN tt.transactiontype = 'Return' THEN 1 ELSE 0 END) AS ReturnCount
        FROM inv.sales_goods sg
        JOIN inv.transactions t ON t.transactionID = sg.saleID
        JOIN inv.transactiontypes tt ON tt.transactiontypeID = t.transactiontypeID
        WHERE sg.barcodeID = ai.barcodeid
          AND t.transactiondate >= @startDate
          AND tt.transactiontype IN ('Sale', 'Return')
    ) ns
    WHERE ns.SaleCount IS NULL OR ns.SaleCount < ns.ReturnCount
);
go

DECLARE @startDate DATE = '20240101';

SELECT *
FROM inv.GetAvailableBarcodesAfterDate(@startDate);
