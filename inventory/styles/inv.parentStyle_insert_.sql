if OBJECT_ID('inv.parentStyle_insert_') is not null drop proc inv.parentStyle_insert_
go
create proc inv.parentStyle_insert_ @brand varchar(max), @article varchar(max), @orderID int 
as
set nocount on;
begin try
	begin transaction	;
	with s (
			orderID, 
			article,
			sizegridID, 
			inventorytypeID, 
			seasonID, 
			brandID, 
			compositionID, 
			workshopID, 
			cost, 
			retail, 
			description, 
			parent_styleid, 
			gender, 
			currencyID
			) 
	as 
			(select 
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
				where p.article = @article) par
			where s.styleID= par.latest
	)
	merge inv.styles as t using s
	on s.orderid = t.orderid
		and s.article = t.article
	when not matched then insert (
			orderID, 
			article,
			sizegridID, 
			inventorytypeID, 
			seasonID, 
			brandID, 
			compositionID, 
			workshopID, 
			cost, 
			retail, 
			description, 
			parent_styleid, 
			gender, 
			currencyID)
	values (
			orderID, 
			article,
			sizegridID, 
			inventorytypeID, 
			seasonID, 
			brandID, 
			compositionID, 
			workshopID, 
			cost, 
			retail, 
			description, 
			parent_styleid, 
			gender, 
			currencyID
	);
	select @@ROWCOUNT rowsAffected
	commit transaction
end try
	
begin catch

end catch


go
declare @brandid int = 343, @styleid int = 21842
, @brand varchar(max) = 'CANOE', @article varchar(max) = 'HARRISON', @orderID int =87051

--exec inv.parentStyle_insert_ @brand= @brand, @article = @article, @orderID = @orderID