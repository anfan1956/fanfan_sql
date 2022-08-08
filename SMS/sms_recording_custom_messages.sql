USE fanfan
go

--DO NOT RUN THE SCRIPT ON LIVE DATA!!!

if OBJECT_ID('sms.phones')is not null drop table sms.phones 
if OBJECT_ID('sms.operators')is	not null drop table sms.operators 

create table sms.operators(
	operatorid int not null identity constraint pk_operators primary key,
	operator VARCHAR (25) NOT NULL CONSTRAINT uq_operator UNIQUE
)
if OBJECT_ID('sms.operator_regions')is not null drop table sms.operator_regions 

create table sms.operator_regions(
	regionid int not null identity constraint pk_operator_regions primary key,
	region VARCHAR (100) NOT NULL CONSTRAINT uq_operator_regions UNIQUE, 
	timezone INT NULL 
)

create table sms.phones(
	phoneid INT NOT NULL IDENTITY CONSTRAINT pk_sms_phones PRIMARY KEY,
	customerid INT NOT NULL CONSTRAINT fk_phones_customers FOREIGN KEY REFERENCES cust.persons (personID),
	phone CHAR(11) NOT null CONSTRAINT uq_phones UNIQUE, 
	countryid INT NOT NULL CONSTRAINT fk_phones_countries FOREIGN KEY REFERENCES cmn.countries (countryID),
	operatorid INT NOT NULL CONSTRAINT fk_phones_operators FOREIGN KEY REFERENCES sms.operators (operatorid), 
	regionid INT NOT NULL CONSTRAINT fk_phones_regions FOREIGN KEY REFERENCES sms.operator_regions (regionid),  
	mcc VARCHAR (25), 
	mnc VARCHAR (25), 
	timezone VARCHAR (25)
)

if OBJECT_ID ('sms.phones_data_update') is not null drop proc sms.phones_data_update
IF TYPE_ID('sms.phone_properties_type') IS NOT NULL DROP TYPE sms.phone_properties_type
GO
CREATE TYPE sms.phone_properties_type AS TABLE (
	phone CHAR(11) , 
	country VARCHAR (25), 
	operator VARCHAR(25), 
	region VARCHAR(155), 
	mcc VARCHAR (25), 
	mnc VARCHAR (25), 
	tz VARCHAR (25)
)
GO

go
create proc sms.phones_data_update 
	@ph_data sms.phone_properties_type READONLY,
	@note varchar (max) output
as 
set nocount on;
declare @message varchar (max)= 'Just debugging'
begin try
	begin TRANSACTION;
		
		-- update operator regions with merge
		WITH s (region, timezone, num) AS (
			SELECT  d.region, d.tz,  
			ROW_NUMBER() OVER (PARTITION BY D.region ORDER BY p.personID DESC)
			FROM @ph_data d
			JOIN cust.connect c1 ON c1.connect= RIGHT(d.phone, 10)
			JOIN cust.persons p ON P.personID=c1.personID
		)
		MERGE sms.operator_regions AS t USING s
		ON t.region=s.region
		WHEN MATCHED AND s.num =1
		THEN UPDATE SET t.timezone=s.timezone
		WHEN NOT MATCHED AND s.num =1
		THEN INSERT(region, timezone)
			VALUES (s.region, s.timezone);

		-- update operators list with merge
		WITH s (operator, num) AS (
			SELECT DISTINCT d.operator,
			ROW_NUMBER() OVER(PARTITION BY D.operator ORDER BY P.personID DESC)
			FROM @ph_data d
				LEFT JOIN cust.connect c1 ON c1.connect= RIGHT(d.phone, 10)
			JOIN cust.persons p ON P.personID=c1.personID
		)
		MERGE sms.operators AS t USING s
		ON t.operator=s.operator
		WHEN NOT MATCHED AND s.num=1
		THEN INSERT(operator)
			VALUES (s.operator);


		-- update phones list with merge
		WITH s 
			(customerid, phone, countryid, operatorid , regionid,	mcc, mnc, timezone, num) 
			AS (
			SELECT DISTINCT 
				p1.personID,
				P.phone, 
				c.countryid, 
				o.operatorid,
				r.regionid, 
				P.mcc, 
				P.mnc,
				P.tz, 
				ROW_NUMBER() OVER (PARTITION BY p.phone ORDER by p1.personid desc)
			FROM @ph_data p
				JOIN cmn.countries c ON c.countryrus=P.country
				JOIN sms.operators o ON o.operator = P.operator
				JOIN sms.operator_regions r ON r.region= P.region
				LEFT JOIN cust.connect c1 ON c1.connect= RIGHT(p.phone, 10)
				LEFT JOIN cust.persons p1 ON p1.personID=c1.personID
		)
		--SELECT s.*, P.lfmname, ROW_NUMBER() OVER(PARTITION BY phone ORDER BY customerid desc) FROM s
			--JOIN cust.persons p ON p.personID=customerid
		MERGE sms.phones AS t USING s
		ON t.phone=s.phone
		WHEN NOT MATCHED AND s.customerid IS NOT null AND s.num=1
		THEN INSERT(customerid, phone, countryid, operatorid , regionid,	mcc, mnc, timezone)
			VALUES (customerid, phone, countryid, operatorid , regionid,	mcc, mnc, timezone)
		WHEN MATCHED AND s.num =1 and
			t.countryid<>s.countryid or
			t.operatorid<>s.operatorid or
			t.regionid<> s.regionid or
			t.mcc<>  s.mcc or
			t.mnc<>s.mnc or
			t.timezone <> s.timezone	
		THEN UPDATE SET
			customerid= s.customerid,
			countryid=s.countryid,
			operatorid=s.operatorid,
			regionid= s.regionid,
			mcc=  s.mcc,
			mnc=s.mnc,
			timezone = s.timezone		
		;
	DECLARE @phones_checked INT = (SELECT COUNT(*) FROM @ph_data)

	set @note = 
		'# of phones checked: ' + CAST(@phones_checked AS VARCHAR(max));
--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
	set @note = ERROR_MESSAGE()
	rollback transaction
end catch
go


-- calling the procedure		
DECLARE @ph_data sms.phone_properties_type;
insert @ph_data (phone, country, operator, region, mcc, mnc, tz) values 
('79637633465', 'Россия', 'Билайн', 'г. Москва и Московская область', '250', '99', '3'), 
('79651404758', 'Россия', 'Билайн', 'г. Москва и Московская область', '250', '99', '3'), 
('79773979827', 'Россия', 'Т2 Мобайл', 'г. Москва и Московская область', '250', '20', '3'), 
('79167834248', 'Россия', 'МТС', 'г. Москва и Московская область', '250', '01', '3'), 
('79037233238', 'Россия', 'Билайн', 'г. Москва и Московская область', '250', '99', '3'), 
('79857278054', 'Россия', 'МТС', 'г. Москва и Московская область', '250', '01', '3'), 
('79256712827', 'Россия', 'Мегафон', 'г. Москва и Московская область', '250', '02', '3')

set nocount on; declare @note varchar (max)
EXEC sms.phones_data_update @ph_data, @note output; select @note

SELECT * FROM sms.operator_regions 
SELECT *FROM sms.operators o
SELECT * FROM sms.phones p
