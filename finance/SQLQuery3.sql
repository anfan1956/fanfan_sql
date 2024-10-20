if OBJECT_ID ('fin.parameters') is not null drop table fin.parameters
go
create table fin.parameters
(
	Id int not null identity, 
	parameterName varchar(255) not null,
	comment varchar(255), 
	parameterValue numeric (14, 4), 
	effectiveDate date not null, 
	divisionId int null
)

;

declare @startDate date = '20200101'
, @rentDate1 date = '2024-07-01' 
, @rentDate2 date = '2024-08-01' 
, @rentDate3 date = '2025-01-01' 

insert fin.parameters (parameterName, comment, parameterValue, effectiveDate, divisionId)
values 
('simplеTax_6' , 'Упрощенка 6%', 0.06, @startDate, null)
, ('rentTurnRate' , 'Процент с оборота ', 0.14, @rentDate1, 27)
, ('rentTurnRate' , 'Процент с оборота ', 0.07, @rentDate2, 27)
, ('rentTurnRate' , 'Процент с оборота ', 0.14, @rentDate3, 27)
, ('VAT' , 'НДС ', 0.2, @startDate, null)
 
go
select * from fin.parameters

if OBJECT_ID ('fin.parValue_f') is not null drop function fin.parValue_f
go
create function fin.parValue_f(@parName varchar (255), @onDate date, @divisionid int = null) returns numeric (14, 4) as
begin 
	declare @value numeric (14, 4)
	select top 1 @value =
			p.parameterValue
		from fin.parameters p
		where p.parameterName = @parName
			and p.effectiveDate <= @onDate
			and ( 1 = isnull(p.divisionId, 1)
			or p.divisionId = @divisionid)

		order by p.effectiveDate desc
	return @value
end
go
declare @date date = getdate();
select fin.parValue_f('simplеTax_6', @date, default)