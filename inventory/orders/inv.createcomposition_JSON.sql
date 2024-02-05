use fanfan
go

if OBJECT_ID ('inv.createcomposition_JSON') is not null drop proc inv.createcomposition_JSON
go

create proc inv.createcomposition_JSON @info dbo.var_decimal_type readonly, @orderid int, @json varchar(max)
as 
set nocount on;
declare @message varchar (max)
begin try
	begin transaction
		DECLARE	@updateComposition bit;

			SET @updateComposition = 1; -- This sets the variable to true
			if (select top 1 i.var1 from @info i) = 'none'
				SET @updateComposition = 0; -- This sets the variable to false			

			declare @style table (
				brand varchar(max), 
				gender varchar(max), 
				category varchar(max), 
				article varchar(max), 
				cost varchar(max), 
				price varchar(max), 
				sizeGrid varchar(max), 
				composition varchar(max), 
				details varchar(max), 
				styleid varchar(max)
			)
			declare @output table (inserted int, updated int)
		
		--  select style data before creating style and insert into parameter table
;		with s (brand, gender, category, article, cost, price, sizeGrid, composition, details, styleid) as 
		(select 
			brand, 
			case gender when 'муж' then 'm' when 'жен' then 'f' end, 
			category, 
			article, cost, price, sizeGrid, composition, details, styleid 
		from OPENJSON(@json)
			with (
				brand varchar(max) '$.Brand',
				gender varchar(max) '$.Gender',
				category varchar(max) '$.Category',
				article varchar(max) '$.Article',
				cost varchar(max) '$.Cost',
				price varchar(max) '$.Price',
				sizeGrid varchar(max) '$."Size Grid"',
				composition varchar(max) '$.Composition',
				details varchar(max) '$.details',
				styleid varchar(max) '$.StyleID'
			) as jsonValue	
		)
		insert @style (brand, gender, category, article, cost, price, sizeGrid, composition, details, styleid)
		select brand, gender, category, article, cost, price, sizeGrid, composition, details, styleid from s;
--		select * from @style;
		declare @styleid  int = (select styleid from @style);

		
		declare @article varchar(max)= (select article from @style);
		declare @r int, @note varchar(max);
		
		if @updateComposition = 1 
			begin
				insert into inv.compositions( orderID ) values ( @orderID );
				select @r=SCOPE_IDENTITY();

				insert inv.compositionscontent (compositionID, materialID, content, orderID)
				select @r compositionID, m.materialID, i.dec1/100 content, @orderid
				from @info i 
					join inv.materials m on m.material=i.var1;
--				select * from inv.compositionscontent where compositionID = @r;
			
		;		with s (orderid, article, sizegridID, inventorytypeid, seasonid, brandid, 
						customscodeid, compositionid, workshopid, cost, retail, description, gender, currencyid
					) as (
				select 
					@orderid orderid, article, sg.sizegridID, it.inventorytypeID, 
					0 seasonid, b.brandID, null customscodeiD, @r compositionid, 
					null workshopid, s.cost, s.price retail, s.details description, 
					s.gender, o.currencyID
				from @style s
					join inv.sizegrids sg on sg.sizegrid=s.sizeGrid
					join inv.inventorytypes it on it.inventorytyperus=s.category
					join inv.brands b on b.brand=s.brand
					join inv.orders o on o.orderID=@orderid
				)
				merge inv.styles as t using s
				on t.orderid = s.orderid and t.article=s.article
				when not matched then insert (orderID, article, sizegridID, inventorytypeID, seasonID, brandID, customscodeID, compositionID, workshopID, cost, retail, description, gender, currencyID)
					values (orderID, article, sizegridID, inventorytypeID, seasonID, brandID, customscodeID, compositionID, workshopID, cost, retail, description, gender, currencyID)
				when matched then update set
					sizegridID = s.sizegridID, 
					inventorytypeID = s.inventorytypeID , 
					seasonID = s.seasonID , 
					brandID = s.brandID , 
					customscodeID = s.customscodeID , 
					compositionID = s.compositionID , 
					--workshopID = s.workshopID , 
					cost = s.cost , 
					retail = s.retail , 
					description = s.description , 
					gender = s.gender , 
					currencyID = s.currencyID
					output inserted.styleid, @styleid into @output
				;

				SELECT @message = 
					CASE 
						WHEN inserted = updated THEN 'updated styleid ' + cast(updated as varchar(max))
						ELSE 'inserted styleid ' + cast(inserted as varchar(max))
					END 
				FROM @output
			end
		else
			begin			
		;		with s (styleid, orderid, article, sizegridID, inventorytypeid, seasonid, brandid, 
						customscodeid, compositionid, workshopid, cost, retail, description, gender, currencyid
					) as (
				select 
					s.styleid,
					@orderid orderid, article, sg.sizegridID, it.inventorytypeID, 
					null seasonid, b.brandID, null customscodeiD, @r compositionid, 
					null workshopid, s.cost, s.price retail, s.details description, 
					s.gender, o.currencyID
				from @style s
					join inv.sizegrids sg on sg.sizegrid=s.sizeGrid
					join inv.inventorytypes it on it.inventorytyperus=s.category
					join inv.brands b on b.brand=s.brand
					join inv.orders o on o.orderID=@orderid
				)
				merge inv.styles  as t using s
				on t.styleid= s.styleid
				when matched then update set 
					t.article = s.article,
					t.sizegridID=s.sizegridID, 
					t.inventorytypeid=s.inventorytypeid,
					t.brandid=s.brandid, 
					t.cost = s.cost, 
					t.retail = s.retail, 
					t.description= s.description, 
					t.gender = s.gender, 
					t.currencyid = s.currencyid
					output inserted.styleid, @styleid into @output;
				--select * from inv.styles s where s.styleID=@styleid;

				SELECT @message = 'updated styleid ' + cast(updated as varchar(max))					
				FROM @output;
			end
;		
select @message  success for json path;				


--	;throw 50001, @message, 1
	commit transaction
end try
begin catch
		select  ERROR_MESSAGE() error for json path
	rollback transaction
end catch
go



go
set nocount on; declare @info dbo.var_decimal_type ; insert @info values ('COTTON', 94), ('ELASTAN', 6); 
declare @json varchar(max); 
select @json = 
'{"Brand":"ADRIANO GOLDSCHMIED","Gender":"жен","Category":"ДЖИНСЫ","Article":"fd/e5","Cost":"45","Price":"90","Size Grid":"JEANS 25-26-…","details":"loose fit","origin":"ИТАЛИЯ","Composition":"Active","StyleID":"20423","Quantity":"0","Total":"0"}'; 
--exec inv.createcomposition_JSON @info, 80033, @json 