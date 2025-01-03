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
	, ROW_NUMBER() over (partition by s.article order by styleid desc) lastNum

from S
)
select p.styleID parent , p.article, p2.styleID  latest
	from _parent p 
	join _parent p2 on p.article= p2.article and p2.lastNum=1
	where p.num =1
go




declare @brandid int = 343, @styleid int = 21842, @brand varchar(max) = 'CANOE', @article varchar(max) = 'NADIA'
, @orderID int =87051
select article from inv.ParentStyles_(@brandid)
select * from inv.styles s where s.styleID = @styleid;

select 
	  orderID = @orderID
	, article = par.article
	, sizegridID = s.sizegridID
	, inventorytypeID = s.inventorytypeID
	, seasonid = o.seasonID 
	, brandID =  inv.brand_id(@brand)
	, compositionID =  s.compositionID
	, workshopID  = s.workshopID
	, cost = s.cost
	, retail = s.retail
	, description= s.description
	, parent_styleid = par.parent
	, gender = s.gender
	, currencyID = o.currencyID
from inv.styles s
	outer apply (
		select seasonid, currencyID from  inv.orders o 
		where o.orderID= @orderID) o
	outer apply (
		select p.latest, p.parent, p.article
		from inv.ParentStyles_(inv.brand_id(@brand)) p
		where p.article = @article
	) par
where s.styleID= par.latest

