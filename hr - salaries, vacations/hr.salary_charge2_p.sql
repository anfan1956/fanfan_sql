use fanfan
go
if OBJECT_ID('hr.salary_charge2_p') is not null drop proc hr.salary_charge2_p
go
create proc hr.salary_charge2_p @note varchar(max) output as 
	set nocount on;
	declare @commission money;
	declare @fistDate date = hr.salary_first_date();
	declare @lastDate date = hr.salary_last_date();
	declare @charges table (personid int, amount money, item varchar(10), condition varchar(255) null)
	declare @transactions table (transactionid int, document varchar(150), person varchar(50))
	declare @warning varchar(max)

	begin try
		begin transaction;

		if hr.salary_next_date_f() >getdate()
			begin
				select @note = 'it is too early';
				throw 50001, @note, 1
			end;

		select @warning = org.checkAttendance_(@lastDate)
		if @warning <> 'OK'
		begin 
				select @note = @warning;
				throw 50001, @note, 1
		end;

		if (select count(*) from org.attendance_check_v) > 0/*other conditiion*/
			begin
				select @note = 'failed attempt. please run org.attendance_check_v';
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

;			with 
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
			-- hardcoding Федоров out because I use myself and Efim for development 
--				where a.personID not in (1, 19)
				where 1=1
					and a.personID not in (1)
					and a.workstationID not in (23)
				)
			, _hours as (
				select a.personid, sum(CONVERT(money, a.t_verified)* (1-2*checktype)*24) wk_hours
				from _attd a
				where cast(a.t_verified as date)>=@fistDate and cast(a.t_verified as date)<=@lastDate
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
				isnull(h.wk_hours, 0) * isnull(f.hour_wage, 0)  hourly, 
				isnull( h.wk_hours, 0)* f.MW_hour  + MW/2 min_wage, 
				(isnull( h.wk_hours, 0)* f.MW_hour  + MW/2) * (hr.parameter_value_f('ставка НДФЛ', null)) PIT,
				(isnull( h.wk_hours, 0)* f.MW_hour  + MW/2) * (hr.parameter_value_f('ЕСН', null)) SocTax
			from 
			hr.compensation_latest_f()f
				left join _hour_share h on h.personid=f.personid			)
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
			insert @charges(personid, amount, item, condition)
			select 
				u.personid, u.amount, u.item, ''
			from _unpivot u
			union all 
			select b.personID, b.amount, b.item, b.condition
			from hr.BunkovoPlazaSalary_p (@lastDate) b
			;

--select * from @charges;			
--	 this is a procedure to record charges data to hr.periodCharges table
			declare @charge hr.chargeType;
			insert @charge (personid, amount, item, condition)
			select p.personid, p.amount, p.item, p.condition
			from @charges p
				
			exec hr.periodCharges_update_ @charge, @lastDate;

--			with s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, comment, document ) as (
			with s (transdate, bookkeeperid, currencyid, articleid, clientid, amount, document, person ) as (
				select 
					transdate  = @lastDate, 
					bookkeeperid = org.user_id('INTERBOT'), 
					currencyid = cmn.currency_id ('RUR'), 
					articleid = 
								case 
									when condition = '/Буньково'
										then acc.article_id('начисление зарплаты/Буньково')
									else
										acc.article_id('начисление зарплаты')
								end, 
					clienid = 
								case 
									when condition = '/Буньково'
										then org.contractor_id ('ИП Федоров')
									else
										org.contractor_id ('ИП ИВАНОВА T. K.')
								end, 
					amount = c.amount, 
					document = c.item,
					person  = p.lfmname
				from @charges c
					join org.persons p on p.personID = c.personid
			)
			insert acc.transactions (transdate, bookkeeperid, currencyid, articleid, clientid, amount, document, comment)
			output inserted.transactionid, inserted.document, inserted.comment into @transactions
			select transdate, bookkeeperid, currencyid, articleid, clientid, amount, document, person from s;

;			with _transactions (transactionid, contractorid, personid, document) as
				(	select 
						t.transactionid, 
						case t.document	 
							when 'PIT' then org.contractor_id('УФК ПО ТУЛЬСКОЙ ОБЛАСТИ')
							when 'SocTax' then org.contractor_id('УФК ПО ТУЛЬСКОЙ ОБЛАСТИ')
							end,
						p.personID, 
						t.document
					from @transactions t
						join org.persons p on p.lfmname = t.person
				)
			, _seed (is_credit, accountid) as (
				select 'TRUE', acc.account_id('зарплата к оплате')
				union all
				select 'FALSE', acc.account_id('зарплата'))
			insert acc.entries (transactionid, is_credit, accountid, contractorid, personid)
			select 
				t.transactionid, s.is_credit, 
				case 
					when t.document in ('PIT', 'SocTax') and s.is_credit='True' then acc.account_id('налоги к оплате')
					else s.accountid end, 
				t.contractorid, t.personid  
			from _transactions t
				cross apply _seed s;

			update s set success= 'True', recorded_time =  CURRENT_TIMESTAMP
			from hr.salary_dates s 
			where s.salary_date =@lastDate;

			select @note = 'зарплата начислена'
			insert hr.salary_jobs_log (result, logtime, salary_date) values (@note, CURRENT_TIMESTAMP, @lastDate)
			;
--			throw 50001, 'debugging', 1;
			
		commit transaction
	end try

	begin catch
		select @note = ERROR_MESSAGE();
		rollback transaction 
		insert hr.salary_jobs_log (result, logtime, salary_date) select @note, CURRENT_TIMESTAMP,  DATEADD(dd, -10,  hr.salary_next_date_f());
	end catch

go
declare @salary_date date = '20250630'
--declare @note varchar(max); exec hr.salarycharge_delete @note output, @salary_date ;select @note
--declare @note varchar(max); exec hr.salary_charge2_p @note output; select @note;

select * from org.attendance_check_v