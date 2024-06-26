if OBJECT_ID('acc.acqRates_v') is not null drop view acc.acqRates_v
go
create view acc.acqRates_v as 


with s as (
select a.*, ROW_NUMBER() over(partition by a.registerid, a.acqTypeid order by datestart desc) num
from acc.acquiring a
	)
select format(s.rate, '#,##0.00%') rate, s.days_off, s.datestart, c.contractor bank, rt.receipttype
from s
	join acc.registers r on r.registerid = s.registerid
	join org.contractors c on c.contractorID=r.bankid
	join fin.receipttypes rt on rt.receipttypeID=acqTypeid
where s.num=1

go
select * from acc.acqRates_v