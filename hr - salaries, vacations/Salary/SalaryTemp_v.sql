if OBJECT_ID('rep.SalaryTemp_v') is not null drop view rep.SalaryTemp_v
go
create view rep.SalaryTemp_v as 
select *
from rep.salaryReport_BEdate_f(getdate())
where 1=1
	and (
/*
	ñòàòüÿ in ('ÍÀ×ÈÑËÅÍÈÅ ÇÀĞÏËÀÒÛ', 'ÍÀ×ÈÑËÅÍÈÅ ÇÀĞÏËÀÒÛ/Áóíüêîâî') 
	and
	äàòà  = '20241215')
*/
transid not in (
16925, 16921, 16920, 16919, 16918, 16917, 16914, 16913, 16912, 16909, 16908, 16907, 16904, 16903, 16902, 16901))
go
select * from rep.SalaryTemp_v