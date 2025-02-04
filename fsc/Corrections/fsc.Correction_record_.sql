IF OBJECT_ID('fsc.Correction_record_') is not null drop proc fsc.Correction_record_
go

CREATE PROCEDURE fsc.Correction_record_ 
    @jsonData NVARCHAR(MAX) -- JSON string parameter
AS
BEGIN
    SET NOCOUNT ON;

    -- Parse the JSON string and extract the required fields
    DECLARE @document_number INT,
            @date_corrected DATETIME,
            @saleid int,
            @year int,
            @month int,
			@day int,
            @fiscal_sign NVARCHAR(100);

    -- Extract values from JSON
    SELECT 
        @document_number = JSON_VALUE(@jsonData, '$.document_number'),
        @year = JSON_VALUE(@jsonData, '$.year'),
        @month = JSON_VALUE(@jsonData, '$.month'),
        @day = JSON_VALUE(@jsonData, '$.day'),
        @saleid = JSON_VALUE(@jsonData, '$.saleid'),
        @fiscal_sign = JSON_VALUE(@jsonData, '$.fiscal_sign');

		set @date_corrected = DATEFROMPARTS(@year, @month, @day);

    -- Update the corrections table
    
	UPDATE rc SET 
		correctionDocNum = @document_number,
        dateCorrected = @date_corrected,
        correctionFisc = @fiscal_sign
	from fsc.ReceiptCorrections rc
    WHERE saleid = @saleid; 

    -- Optionally, return the number of rows affected
    select @@ROWCOUNT;

END;
go

--exec fsc.Correction_record_ @jsonData = '{"document_number": 199, "fiscal_sign": "3463143148", "saleid": "87010", "year": 2024, "month": 12, "day": 7}';
select * from fsc.ReceiptCorrections where dateCorrected is not null
select * 
from fsc.ReceiptCorrections c
where c.docNo in (6, 47)

select s.*, t.transactiondate, sr.amount
from inv.sales s 
	join inv.sales_receipts sr on sr.saleID = s.saleID
	join inv.transactions t on t.transactionID=s.saleID 
where s.receiptid in (38)