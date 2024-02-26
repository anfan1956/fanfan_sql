if OBJECT_ID('org.divisionJobs_') is not null drop function org.divisionJobs_
go
create function org.divisionJobs_(@divisionid int) returns table as return
select pd.pricesetID id, ps.pricesetdate дата, p.lfmname сотрудник, count (pd.barcodeID) количество
from inv.pricesets_divisions pd
	join inv.pricesets ps on ps.pricesetID=pd.pricesetID
	join org.persons p on p.personID=ps.userID
where pd.printtime is null and pd.divisionID = @divisionid
group by pd.pricesetID, ps.pricesetdate, p.lfmname
--order by 1 desc;

go

--select id, дата, сотрудник, количество from org.divisionJobs_ (27)

select * 

from inv.pricesets_divisions p where p.printtime is null


select * from inv.pricesets p order by 1 desc
select * from inv.pricesets_divisions order by 1 desc