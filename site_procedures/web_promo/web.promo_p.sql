﻿if OBJECT_ID ('web.promo_p') is not null drop proc web.promo_p
go
create proc web.promo_p 
	@phone char(10), 
	@styleid int, 
	@note varchar(max) output 
as
	set nocount on;

begin try
	begin transaction;
		declare @code char(6) = (select code from cmn.random_6)
		declare 
			@r int, 
			@logid int,
			@custid int, 
			@discount dec(4,3),
			@datefinish date,
			@prString as varchar(max), 
			@salesperson varchar(25) = 'INTERBOT', 
			@shop varchar(25)= 'FANFAN.STORE';


-- не забыть подумать о том, если события будут пересекаться
		declare @eventid int = (
			select top 1 p.eventid 
			from web.promo_events p
				join web.promo_styles_discounts ps on ps.eventid=p.eventid
			where cast(getdate() as date) between p.datestart and p.datefinish
				and ps.styleid =@styleid
			);		

		if @eventid is not null
			begin
				select @datefinish = 
					p.datefinish 
					from web.promo_events p 
					where p.eventid= @eventid;

				select @prString = 
					--concat('бренд: ' + b.brand, ';  артикул:' + s.article) 
					--from inv.styles s
					--	join inv.brands b on b.brandID=s.brandID
					--where s.styleID = @styleid
					concat(b.brand, ', модель ' + cast(@styleid as varchar(max)), '. Купить - позвоните по телефону 495-902-7130 ') 
					from inv.styles s
						join inv.brands b on b.brandID=s.brandID
					where s.styleID = @styleid

				select @custid = cust.customer_id(@phone);
				if @custid is null 
					begin
						exec @r = cust.cust_registration_tsheets_p 
								@salesperson = @salesperson, 
								@shop = @shop, 
								@fname = null, 
								@mname = null, 
								@lname = null, 
								@gender = null, 
								@d_of_b = null, 
								@phone = @phone, 
								@mail= null, 
								@note = @note output;
							select @custid=@r;
						--select @note 'customer is not registered'
					end
				--else if @custid is not null 
					
						select @discount =
							w.discount
							from web.promo_styles_discounts w
							where w.eventid= @eventid 
								and w.styleid=@styleid

						insert web.promo_log (eventid, styleid, discount, custid, promocode) 
						select @eventid, @styleid, @discount, @custid, @code;
						select @logid = SCOPE_IDENTITY();
						declare @count int = (select count(*) from web.promo_log where logid =@logid);


						--from web.promo_styles_discounts w;
						update pl set pl.used =  'True'
						from web.promo_log pl
						where pl.custid=@custid 
							and pl.eventid=@eventid 
							and pl.styleid= @styleid
							and pl.logid<@logid
						declare @disc money = (select distinct discount from inv.style_photos_f(@styleid));

						select @note = '-' + format (@discount, '#,##0%' ) + ' по промокоду ' + @code + ' до '  + FORMAT(@datefinish, 'dd.MM.yy') + '. ' + @prString  ;
						if @disc>0 select @note = 'Дополнительно ' + @note ;			
			end
		else select @note = 'сейчас на этот артикул промокода нет'
--		throw 50001, @note, 1;
	commit transaction
end try

begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch	
go
--declare @styleid int = 19363
declare @styleid int = 19629


set nocount on;declare @phone char (10) ='9167834248', @note varchar(max); exec web.promo_p @phone, @styleId, @note output; select @note;
	
