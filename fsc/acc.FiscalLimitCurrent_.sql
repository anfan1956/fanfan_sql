if OBJECT_ID('acc.FiscalLimitCurrent_') is not null drop function acc.FiscalLimitCurrent_
go

create function acc.FiscalLimitCurrent_(@divisionID int )
returns money as 
begin 
	declare @limit money;
	select top 1  @limit = limit
		from acc.divisionFiscalLimit l where 
		l.divisionID = @divisionID
		order by l.EffectiveFrom desc
	return isnull( @limit, null)
end

go

declare @divisionID int = 27
select acc.FiscalLimitCurrent_(@divisionID)