﻿
if OBJECT_ID('hr.salary_charge2_p') is not null drop proc hr.salary_charge2_p
go
create proc hr.salary_charge2_p @note varchar(max) output as 
	set nocount on;
	declare @commission money;
	declare @fistDate date = hr.salary_first_date();
	declare @lastDate date = hr.salary_last_date();
	declare @charges table (personid int, amount money, item varchar(10))
	declare @transactions table (transactionid int, document varchar(150), person varchar(50))
	begin try
		begin transaction;

		if hr.salary_next_date_f() >getdate()
			begin
				select @note = 'it is too early';
				throw 50001, @note, 1
			end;


			-- calculate total commission charge for the period
			with 
			_sales as (
				select sr.receipttypeID, sum (sr.amount * iif(tt.transactiontypeID = 13, -1, 1)) amount
				from inv.sales_receipts sr
					join inv.transactions t on t.transactionID= sr.saleID
					join inv.transactiontypes tt on tt.transactiontypeID=t.transactiontypeID
					where cast(t.transactiondate as date)>=hr.salary_first_date() and cast (t.transactiondate as date) <= hr.salary_last_date()
				group by sr.receipttypeID
			)
			SELECT @commission = sum(s.amount * r.rate) over () 
			from _sales s
				join hr.latest_comm_rates_date_f(@fistDate) r on r.receipttypeid= s.receipttypeID;


			with 
			 _attd (personid, checktype, t_verified) as (
				select 
					a.personid, a.checktype, 
						case 
							when checktype=1 
								and CAST(checktime as time(0))<cast('10:00' as time(0)) 
								and superviserID is null 
									then DATEADD(hh, 10, dbo.justdate(checktime))
							when checktype=0 
								and CAST(checktime as time(0))>cast('22:00' as time(0)) 
								and superviserID is null 
									 then DATEADD(hh, 22, dbo.justdate(checktime))
							else checktime end t_verified
				from org.attendance a
				)
			, _hours as (
				select a.personid, sum(CONVERT(money, a.t_verified)* (1-2*checktype)*24) wk_hours
				from _attd a
				where a.t_verified>=@fistDate and a.t_verified<=@lastDate
				group by a.personID
			)
			, _hour_share as (
				select  h.wk_hours, h.wk_hours/ sum(wk_hours)  over () share, h.personid 
				from _hours h
			)
			, _s_charges (personid, fixed, commission, hourly, min_wage, PIT, SocTax) as (
			select 
				f.personid, 
				f.fixed_wage/2 fixed, 
				isnull(h.share * @commission, 0) commission ,
				isnull(f.hour_wage * h.wk_hours, 0) hourly, 
				isnull(f.MW_hour* h.wk_hours, f.MW/2) min_wage, 
				isnull(f.MW_hour* h.wk_hours, f.MW/2) * (hr.parameter_value_f('ставка НДФЛ', null)) PIT,
				isnull(f.MW_hour* h.wk_hours, f.MW/2) * (hr.parameter_value_f('ЕСН', null)) SocTax
			from 
			hr.compensation_latest_f()f
				left join _hour_share h on h.personid=f.personid
			)
			, _final as (
			select 
				s.personid, 
				fixed + commission + hourly total, 
				fixed + commission + hourly - min_wage cash, 
				min_wage - PIT bank,
				PIT,
				SocTax
			from _s_charges s
			)
			, _unpivot as (
			select personid, amount, item
			from (
					select * 
					from _final
				) f
			unpivot (amount for item in (cash, bank, pit, SocTax)) as pt
			where amount <>0
			) 
			insert @charges(personid, amount, item)
			select 
				u.personid, u.amount, u.item
			from _unpivot u;
			
--			with s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document ) as (
			with s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, document, person ) as (
				select 
					@lastDate, 
					org.user_id('INTERBOT'), 
					cmn.currency_id ('RUR'), 
					acc.article_id('начисление зарплаты'), 
					org.contractor_id ('ИП Федоров'), 
					c.amount, 
					c.item,
					p.lfmname
				from @charges c
					join org.persons p on p.personID = c.personid
			)
			insert acc.transactions (transdate, bookkeeperid, currencyid, articleid, clientid, amount, document, comment)
			output inserted.transactionid, inserted.document, inserted.comment into @transactions
			select transdate, bookkeeperid, currencyid, articleid, clientid, amount, document, person from s;
			;


			with _transactions (transactionid, contractorid, personid) as
				(	select 
						t.transactionid, 
						case t.document	 
							when 'PIT' then org.contractor_id('ИФНС по г. Красногорск Московской области')
							when 'SocTax' then org.contractor_id('ИФНС по г. Красногорск Московской области')
							end,
						p.personID
					from @transactions t
						join org.persons p on p.lfmname = t.person
				)
			, _seed (is_credit, accountid) as (
				select 'TRUE', acc.account_id('зарплата к оплате')
				union all
				select 'FALSE', acc.account_id('зарплата'))
			insert acc.entries (transactionid, is_credit, accountid, contractorid, personid)
			select t.transactionid, s.is_credit, s.accountid, t.contractorid, t.personid  
			from _transactions t
				cross apply _seed s;

			update s set success= 'True', recorded_time =  CURRENT_TIMESTAMP
			from hr.salary_dates s 
			where s.salary_date =@lastDate;

			select @note = 'зарплата начислена'
			insert hr.salary_jobs_log (result, logtime, salary_date) values (@note, CURRENT_TIMESTAMP, @lastDate)
			;
			--throw 50001, 'debugging', 1;
			
		commit transaction
	end try

	begin catch
		select @note = ERROR_MESSAGE();
		rollback transaction 
	end catch

go
declare @salary_date date = '20221130'
--declare @note varchar(max); exec hr.salarycharge_delete @note output, @salary_date ;select @note
--declare @note varchar(max); exec hr.salary_charge2_p @note output; select @note;

--select top 1 * from acc.transactions order by 1 desc
--select * from acc.entries

select * from acc.transactions t
	join acc.entries e on e.transactionid= t.transactionid	
where articleid = 13 
	and comment = 'ШЕМЯКИНА Е. В.'
order by 1 desc 