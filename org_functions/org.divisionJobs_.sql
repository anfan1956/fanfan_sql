if OBJECT_ID('org.divisionJobs_') is not null drop function org.divisionJobs_
go
create function org.divisionJobs_(@divisionid int) returns table as return
with cte as (
	select distinct ps.pricesetID, s.brandID
	from inv.prices p
		join inv.pricesets ps on ps.pricesetID = p.pricesetID
		join inv.styles s on s.styleID =p.styleID
)
select 
	pd.pricesetID id, ps.pricesetdate дата, 
	--br.brand марка, 
	p.lfmname сотрудник, 
	br.brand марка, 
	count (pd.barcodeID) количество
from inv.pricesets_divisions pd
	join inv.pricesets ps on ps.pricesetID=pd.pricesetID
	join org.persons p on p.personID=ps.userID
	join cte on cte.pricesetID=pd.pricesetID
	join inv.brands br on br.brandID = cte.brandID
where pd.printtime is null and pd.divisionID = @divisionid
group by pd.pricesetID, ps.pricesetdate, p.lfmname, br.brand
	--, br.brand
--order by 1 desc;

go

select 
	id, дата, сотрудник, 
	марка, 
	количество from org.divisionJobs_ (18)

select * 

from inv.pricesets_divisions p where p.printtime  is null
 and divisionID =18


--select * from inv.pricesets p where p.pricesetID = 11153 order by 1 desc
--select * from inv.pricesets_divisions p where p.pricesetid = 11153 order by 1 desc