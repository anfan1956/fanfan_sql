

if OBJECT_ID('inv.ParentStyles_') is not null drop function inv.ParentStyles_
go
create function inv.ParentStyles_ (@brandid int ) returns table as return

with s as (
	select 
		styleID, 
		trim(right(article , len(article)- charindex(' ', article))) article	
	from inv.styles s 
	where s.brandID = @brandid
) 
, _parent as (
select 
	s.styleID
	, s.article
	, ROW_NUMBER() over (partition by s.article order by styleid) num
from S
)
select styleID , article
from _parent p where p.num =1
go
declare  @vendorid  int = 607
declare @brandid int = 343
select * from inv.ParentStyles_(@brandid)

