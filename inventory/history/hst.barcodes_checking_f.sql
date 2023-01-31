use fanfan
go

select * from hst.barcodes_read --where date_checked= @date
;

if OBJECT_ID('hst.barcodes_checking_f') is not null drop function hst.barcodes_checking_f
go
create function hst.barcodes_checking_f (@date as date ) returns table as return
with _persons  as (
	select 
		a.personID, a.workstationID, 
		a.checktime time_in, a.checktype,
		lead(a.checktime) over (partition by personid order by checktime) time_out
	from org.attendance a 
where cast(checktime as date)= cast(@date as date)
)
, _checked as (
select 
	b.barcodeid,
	p.personID, 
	pr.lfmname, 
	b.date_checked,
	--p.workstationID, 
	--time_in, 
	--time_out, 
	wd.divisionfullname division, 
	b.procid, 
	ROW_NUMBER() over(partition by b.barcodeid, p.personid order by b.date_checked desc) num
from _persons p
	join hst.barcodes_read b on b.date_checked > p.time_in and b.date_checked < isnull(time_out, getdate())
	join org.persons pr on pr.personID = p.personID
	join org.workstations_divisions_current_v wd on wd.workstationid=p.workstationID
		and wd.datestart < @date and wd.workstationid=b.workstationid
where checktype =1
)
select 
	c.barcodeid, c.personID, 
	c.lfmname registered, 
	c.date_checked last_checked, 
	c.division division_checked, 
	pr.procname check_type,  
	br.brand, it.inventorytype category, s.article, sz.size, cl.color, 	
	d.divisionfullname current_location
from _checked c
	join inv.barcodes b on b.barcodeID = c.barcodeid
	join inv.styles s on s.styleID = b.styleID
	join inv.sizes sz on sz.sizeID=b.sizeID
	join inv.colors cl on cl.colorID=b.colorID
	join inv.brands br on br.brandID=s.brandID
	join inv.inventorytypes it on it.inventorytypeID = s.inventorytypeID
	join inv.v_remains r on r.barcodeID=c.barcodeid
	join inv.logstates l on l.logstateID= r.logstateID
	join org.divisions d on d.divisionID=r.divisionID
	join hst.procs pr on pr.procid=c.procid
where 
	l.logstate = 'IN-WAREHOUSE'
	and num = 1
go

declare @date date = '2023-01-31'
select * from hst.barcodes_checking_f(getdate())
order by 4