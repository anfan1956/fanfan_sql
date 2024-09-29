if OBJECT_ID('cmn.TaxRates') is not null drop table cmn.TaxRates
if OBJECT_ID('cmn.Regions') is not null drop table cmn.Regions
if OBJECT_ID('cmn.TaxNames') is not null drop table cmn.TaxNames

CREATE TABLE cmn.TaxNames (
    TaxNameID INT PRIMARY KEY IDENTITY(1,1),
    TaxName VARCHAR(100) NOT NULL UNIQUE, 
	Description VARCHAR(255) 
);

CREATE TABLE cmn.Regions (
    RegionID INT PRIMARY KEY IDENTITY(1,1),
    RegionName VARCHAR(100) NOT NULL UNIQUE,
    AdditionalInfo VARCHAR(255) null
);

CREATE TABLE cmn.TaxRates (
    TaxRateID INT PRIMARY KEY IDENTITY(1,1),
    TaxNameID int foreign key references cmn.TaxNames (TaxNameID),
    Rate DECIMAL(5, 2),
    EffectiveDate DATE,  
    RegionID int foreign key references cmn.Regions (RegionID),
  	constraint uqTax unique (taxNameID, effectiveDATE, RegionID)
);

insert cmn.TaxNames (TaxName, Description) 
values ('TurnOverTaxSimplified', 'Упрощенка для ИП с оборота')

insert cmn.Regions (RegionName, AdditionalInfo) 
values ('Russia', 'Main region')

insert cmn.TaxRates (TaxNameID, Rate, EffectiveDate, RegionID)
values 
	(1, 0.06, '20240101', 1)	
select * from cmn.TaxRates
if OBJECT_ID('cmn.TurnoverTaxSimple') is not null drop function cmn.TurnoverTaxSimple
go
CREATE FUNCTION cmn.TurnoverTaxSimple (
    @Date DATE = NULL,
    @Region VARCHAR(100) ='Russia' 
)
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @TaxRate DECIMAL(5, 2);

    -- Use the current date if no date is provided
    IF @Date IS NULL
    BEGIN
        SET @Date = GETDATE();
    END

;    with _taxRate (Rate, Num) as (
		select 
			tr.Rate 
			, ROW_NUMBER() over (order by tr.effectiveDate desc) 
		from cmn.TaxRates tr 
			join cmn.Regions r on r.RegionID = tr.RegionID
			join cmn.TaxNames tn on tn.TaxNameID=tr.TaxNameID
		where 
			tr.EffectiveDate<=@Date
			and r.RegionName = @Region
			and tn.TaxName = 'TurnOverTaxSimplified'
	)
	select @TaxRate = Rate
	from _taxRate t where t.Num =1
    RETURN @TaxRate;
END;
go
select cmn.TurnoverTaxSimple(default, default)





