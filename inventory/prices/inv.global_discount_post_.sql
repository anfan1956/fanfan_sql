if OBJECT_ID('inv.global_discount_post_') is not null drop proc inv.global_discount_post_
go
create proc inv.global_discount_post_ @info dbo.id_money_type readonly, @user varchar (max), @discountType varchar(max)
as 
set nocount on;
	begin try
		begin transaction;
			declare @mes varchar(max), @count int;		
			declare @pricesetid int;

			insert inv.pricesets (pricetypeid, userid, comment) 
				select inv.pricetype_id('sale'), org.person_id(@user), 'global discount proc' 
			select @pricesetid = SCOPE_IDENTITY();

			if (@discountType ='новая скидка') 
				begin
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
			else if (@discountType ='новая цена') 
				begin 
					; with s (styleid, price, discount, num) as (
						select s.styleID, i.amount, p.discount, ROW_NUMBER() over (partition by p.styleid order by p.pricesetid desc) num
						from @info i 
							join inv.styles s on s.styleid=i.id
							join inv.prices p on s.styleid =p.styleID							
					)
					insert inv.prices (pricesetID, styleID, price, discount)					
					select @pricesetid, styleid, price, discount
					from s where s.num =1;	
					select @count = @@ROWCOUNT
					select @mes = cast(@count as varchar(max)) + ' styles prices updated'					
				end
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

				insert inv.pricesets_divisions (pricesetID, divisionID, barcodeID)
				select @pricesetid pricesetid, i.divisionid, b.barcodeID
				from inv.inventory i 
					join inv.barcodes b on b.barcodeID=i.barcodeID
					join inv.styles s on s.styleID=b.styleID
					join inv.prices p on p.styleID=b.styleID
	
				where 
					i.logstateID  in (inv.logstate_id('in-warehouse'))
					and p.pricesetID= @pricesetid
				group by i.divisionID, b.barcodeID, p.price
				having sum(i.opersign)>0


				select 0 success, @mes message;
--			throw 50001, 'debug', 1
		commit transaction
	end try
	begin catch
		select -1 error, ERROR_MESSAGE() message
		rollback transaction
	end catch
go


declare @pricesetid int = 11152, @brandid int = 103, @divisionid int = 18
set nocount on; 
declare @info dbo.id_money_type; 
insert @info values ( 17055,  1701), ( 16092,  1131); 
--exec inv.global_discount_post_ @info, 'ЛАЗАРЕВА Н. В.', 'новая цена'


--select * from inv.pricesets ps left join inv.prices pr on pr.pricesetID=ps.pricesetID where ps.pricesetID = @pricesetid order by 1 desc;




select id, дата, сотрудник, количество from org.divisionJobs_ (27)

