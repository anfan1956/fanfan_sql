use fanfan
go

if OBJECT_ID ('inv.articlesUpdate_') is not null drop proc inv.articlesUpdate_
go

create proc inv.articlesUpdate_  @info dbo.id_type readonly, @userid int, @article  varchar (max) output
as 
set nocount on;
begin try
	begin transaction;
		declare @message varchar (max)= 'Just debugging'

		declare @pricesetid int ;

		with _st(inventorytypeID) as
		(
			select top 1 inventorytypeID
			from inv.styles s join @info i on i.Id=s.styleID
			order by s.styleID desc
		)
		update s set s.article= @article, s.inventorytypeID = _st.inventorytypeID
		from @info i
			join inv.styles s on s.styleID = i.id
			cross apply _st;
--		select s.* from inv.styles s join @info i on i.Id=s.styleID;
	
		insert inv.pricesets (pricetypeID, pricesetdate, userID, comment)
		values (3, CURRENT_TIMESTAMP, @userid, 'article adjustment')
		select @pricesetid = SCOPE_IDENTITY();

		with _s (price, discount, num) as (
			select 
				p.price, p.discount, ROW_NUMBER() over( order by p.pricesetid desc) num
			from inv.prices p
				join @info i on i.Id = p.styleID
		)
		insert inv.prices (pricesetID, styleID, price, discount)		
			select @pricesetid, i.Id, s.price, s.discount
			from @info i
			cross apply _s s
			where num = 1;

			insert inv.pricesets_divisions (pricesetID, divisionID, barcodeID)
			select p.pricesetID, i.divisionID, i.barcodeID
			from inv.prices p 
				join inv.barcodes b on b.styleID=p.styleID				
				join inventory i on i.barcodeID = b.barcodeID
			where p.pricesetID= @pricesetid and i.logstateID = inv.logstate_id('in-warehouse')
			group by p.pricesetID, i.divisionID, i.barcodeID
			having sum (i.opersign )>0


		--;throw 50001, @message, 1
	commit transaction
end try
begin catch
	select ERROR_MESSAGE()
	rollback transaction
end catch
go

set nocount on; 
declare @info dbo.id_type, @userid int = 1; 
insert @info values (11658), (10181), (9865); 
--exec inv.articlesUpdate_ @info, @userid, '14435 AIRPORT'
--select top 5 * from inv.pricesets p order by 1 desc;
--select * from inv.current_stock_v c join @info i on i.Id =  c.styleID where магазин = '05 УИКЕНД'


select * from inv.pricesets_divisions 
where printtime is null
order by 1 desc

