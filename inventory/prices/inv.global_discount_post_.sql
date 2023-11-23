if OBJECT_ID('inv.global_discount_post_') is not null drop proc inv.global_discount_post_
go
create proc inv.global_discount_post_ @info dbo.id_money_type readonly, @user varchar (max), @discountType varchar(max)
as 
set nocount on;
	begin try
		begin transaction;
			declare @mes varchar(max), @count int;		
			if (@discountType ='новая скидка') 
				begin
					declare @pricesetid int;
					insert inv.pricesets (pricetypeid, userid, comment) 
						select inv.pricetype_id('sale'), org.person_id(@user), 'global discount proc' 

					select @pricesetid = SCOPE_IDENTITY();

					; with s (styleid, price, discount, num) as (
						select p.styleID, p.price, i.amount, ROW_NUMBER() over (partition by p.styleid order by p.pricesetid desc) num
						from @info i 
							join inv.prices p on p.styleID =i.id
					)
					insert inv.prices (pricesetID, styleID, price, discount)					
					select @pricesetid, styleid, price, discount
					from s where s.num =1;	
					select @count = @@ROWCOUNT
					select @mes = cast(@count as varchar(max)) + ' styles discounts updated'
				end;
			else if (@discountType ='новая промо') 			
				begin
					declare @eventid int;
					select @eventid = e.eventid
					from web.promo_events e 
						where cast(getdate() as date) between e.datestart and e.datefinish
						and e.eventClosed = 'False';
					
					with s (eventid, styleid, discount) as (
						select @eventid, i.id, i.amount
						from @info i 
					)
					merge web.promo_styles_discounts as t using s
					on t.eventid=s.eventid 
						and t.styleid = s.styleid
					when matched then 
					update set
						t.discount = s.discount
					when not matched then 
						insert (eventid, styleid, discount)
						values ( eventid,styleid, discount )
						;
					select @count = @@ROWCOUNT
					select @mes = cast(@count as varchar(max)) + ' styles promo updated'
				end;
			else if (@discountType = 'новая цена')
				begin;
					with src (parentid, styleid, price, num, cost, currencyid) as (
					select p.styleID, s.styleID, i.amount, ROW_NUMBER() over (partition by p.styleid order by s.styleid), 
						p.cost, o.currencyID
					from @info i
						join inv.styles s on s.styleID=i.id
						join inv.styles p on p.styleID=s.parent_styleid
						join inv.orders o on o.orderID= p.orderID
					)
					, adj as (
					select 
						s.parentid, 
						round(s.price/s.cost/r.rate/r.markup, 4) cost_adj
					from src s
						join inv.current_rate_v r on r.currencyid=s.currencyid and r.divisionid=org.division_id('FANFAN.STORE')
					where s.num =1
					)
					update s set s.cost_adj = a.cost_adj
					from adj a
						join inv.styles s on s.styleID=a.parentid;
					
					select @count = @@ROWCOUNT
					select @mes = cast(@count as varchar(max)) + ' styles cost_adj updated'
				end
				select 0 success, @mes message;
			--throw 50001, 'debug', 1
		commit transaction
	end try
	begin catch
		select -1 error, ERROR_MESSAGE() message
		rollback transaction
	end catch
go

set nocount on; 
declare @info dbo.id_money_type; insert @info values 
	(18122, 19125)

--	( 19468,  .45), ( 17306,  .45), ( 18297,  .45), ( 18300,  .45), ( 18301,  .45), ( 18303,  .13), ( 19472,  .13), ( 19473,  .13), ( 19474,  .13), ( 19482,  .13), ( 19483,  .13), ( 19484,  .13), ( 19485,  .13), ( 16243,  .12); 
--exec inv.global_discount_post_ @info, 'ФЕДОРОВ А. Н.', 'новая цена'



--select * from inv.pricesets s order by 1 desc


--select * from inv.prices order by 1 desc


