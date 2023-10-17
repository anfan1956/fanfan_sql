

if OBJECT_ID ('web.promoAllStyles_p') is not null drop proc web.promoAllStyles_p
go
create proc web.promoAllStyles_p
	@phone char(10), 
	@note varchar(max) output 
as
	set nocount on;

--hardcoded the site link
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
			@salesperson varchar(25) = 'INTERBOT F. ', 
			@shop varchar(25)= 'FANFAN.STORE';


-- не забыть подумать о том, если события будут пересекаться
		declare @eventid int = (
			select top 1 p.eventid 
			from web.promo_events p
			where cast(getdate() as date) between p.datestart and p.datefinish
			);		

		if @eventid is not null
			begin
				select @datefinish = 
					p.datefinish 
					from web.promo_events p 
					where p.eventid= @eventid;

				select @prString = 
					 'http://fanfan.store/promo телефон: 8-495-902-7130' 
					from inv.styles s
						join inv.brands b on b.brandID=s.brandID

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


						insert web.promo_log (eventid, custid, promocode) 
						select @eventid,  @custid, @code;
						select @logid = SCOPE_IDENTITY();
						declare @count int = (select count(*) from web.promo_log where logid =@logid);


						--from web.promo_styles_discounts w;
						update pl set pl.used =  'True'
						from web.promo_log pl
						where pl.custid=@custid 
							and pl.eventid=@eventid 
							and pl.logid<@logid

						select @note = 'промокод ' + @code + ' до '  + FORMAT(@datefinish, 'dd.MM.yy') + ' ' + @prString  ;
			end
		else select @note = 'сейчас промоакций нет'
--		throw 50001, @note, 1;
	commit transaction
end try

begin catch
	select @note = ERROR_MESSAGE()
	rollback transaction
end catch	
go

declare @note varchar(max), @phone char (10) = '9818933422', 
	@salesperson varchar(25) = 'INTERBOT F. ' 

exec web.promoAllStyles_p @phone, @note output; select @note

--select * from web.promo_log order by 1 desc
select cust.customer_id(@phone)
