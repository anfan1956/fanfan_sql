if OBJECT_ID ('acc.rentAccount_v') is not null drop view acc.rentAccount_v
go 
create view acc.rentAccount_v as
	select * from acc.turnoverCharges_v
union all 
	select * from acc.rentPayments_v
union all 
	select 
		operDate		= '20241020'
		, operId		= 0
		, operType		= '��� �������������'
		, division		= '05 ������'
		, customer		= ''
		, pmtType		= '�������������'
		, fiscalDocNum	= '�������������_1'
		, amount		= 23671.11
		, chargeType	= 'rent'
		, charge		= 23671.114
		, operYear		= DATEPART(YEAR, '20241020')
		, operMonth		= DATEPART(MONTH, '20241020')
		, operDay		= DATEPART(DAY, '20241020')
		, journal		= 'adjustments'

go
select * from acc.rentAccount_v