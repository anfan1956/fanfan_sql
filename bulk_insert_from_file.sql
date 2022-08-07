if OBJECT_ID('tmp.sms')is not null drop table tmp.sms 
create table tmp.sms(
	phone CHAR(11) , 
	country VARCHAR (25), 
	operator VARCHAR(25), 
	region VARCHAR(155), 
	mcc VARCHAR (25), 
	mnc VARCHAR (25), 
	tz VARCHAR (25)
)
go
BULK INSERT tmp.sms
FROM "D:\Development\jobs\operators.txt"
WITH
(
	CODEPAGE = '65001',
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    TABLOCK
)
SELECT * FROM tmp.sms s
