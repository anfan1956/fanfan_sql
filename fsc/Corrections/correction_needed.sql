if not exists (
	select 1 
	from sys.columns s 
	where 1=1
	and object_id = object_id('inv.sales')
	and s.name = 'correction_needed'
	)
alter table inv.sales
add correction_needed bit null

select * from inv.sales s
order by 1 
