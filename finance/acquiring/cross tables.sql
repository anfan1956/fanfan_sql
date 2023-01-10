declare @date date = '20221111';

--select  top 1 * from acc.balance_trial_f (@date);
with _dates (datestart, dateend) as (
	select dateadd(DD, 1, EOMONTH(@date, -1)), EOMONTH(@date, 0)

)
select sr.*, acqType
from inv.transactions t 
	join inv.sales_receipts sr on sr.saleID=t.transactionID
	cross apply _dates d 
	left join acc.cross_table_rectypes c on c.acqTypeid=sr.receipttypeID
where cast(t.transactiondate as date) between d.datestart and d.dateend

select * from fin.receipttypes

--alter table  fin.receipttypes add acqTypeid int null
select *, 
	case 
		when r.receipttypeID in (1, 3, 6 ) then 3
		when r.receipttypeID in (2, 5) then 5
		when r.receipttypeID in (7) then 7 
		when r.receipttypeID in (8) then	8
	end
from fin.receipttypes r
select * from acc.cross_table_rectypes

--if OBJECT_ID ('acc.rectypes_acqTypes') is not null drop table acc.rectypes_acqTypes
--go
--create table acc.rectypes_acqTypes (
--	receipttypeID int , 
--	acqTypeid int
--)

--go 
--insert acc.rectypes_acqTypes values 
--(1,3), 
--(3,3), 
--(6,3), 
--(2,5), 
--(5,5), 
--(7,7), 
--(8,8)

select * from acc.rectypes_acqTypes
go
declare @date date = '20221231';

select * from inv.transactions t 
join inv.sales_receipts sr on sr.saleID=t.transactionID
where cast(t.transactiondate as date) = @date