if OBJECT_ID('acc.divisionFiscalLimit') is not null drop table acc.divisionFiscalLimit
go
create table acc.divisionFiscalLimit (
	divisionID int not null foreign key references org.divisions (divisionid), 
	EffectiveFrom date not null, 
	limit money null, 
	constraint PK_div_fiscalLimit primary key clustered (divisionid, EffectiveFrom)
)
insert acc.divisionFiscalLimit (divisionID, EffectiveFrom, limit)
select 
	divisionid = 27, 
	effectiveFrom  = '20250101', 
	limit = 160000

select * from acc.divisionFiscalLimit