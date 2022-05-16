USE [fanfan]
GO
/****** Object:  StoredProcedure [hr].[salary_charge_p]    Script Date: 16.05.2022 20:39:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [hr].[salary_charge_p] @note varchar(max) output as 

--	declare @mydate date = cast (getdate() as date)
	declare @startdate date = dateadd(d, 1, hr.last_date()), @update date = hr.upcoming_date(), 
	@currenttime datetime =  current_timestamp;
	declare @transactions table (
		transactionid int, currencyid int, transactiondate datetime, 
		detailsid int, clientid int, comment varchar(255)
	);
	declare @entries table (
		entryid int, 
		transactionid int, 
		entrydate datetime, 
		userid int, 
		accountid int,
		contractorid int, 
		is_credit bit, 
		journalid int,
		amount money
	)

	begin try
		begin transaction;
			if not( datediff(D, hr.upcoming_date(), cast(CURRENT_TIMESTAMP as date))>=10
				and (select success from hr.salary_dates d where d.salary_date=hr.upcoming_date() ) is null)
				begin
					select @note = 'either to early or already done'
					;throw 50001, @note, 1;		
				end ;

				/*create new transactions, one transaction per personid */
				with s (personid, currencyid, transactiondate, detailsid, clientid, comment) as (
					select distinct 
						h.personid,
						cmn.currency_id('RUR'), 
						@update transactionidate, anfan_release.acc.details_id('начисление зарплаты'), c.clientid, 						
						cast(af.contractorid as varchar (max)) + ', '  + p.lfmname + ', начисление з/п,  ' + cl.clientRus
					from hr.salary_charge_f(@startdate, @update) h
						join org.persons p on p.personID = h.personid
						join anfan_release.org.contractors af on af.personid_ff=h.personid
						join org.clients cl on cl.clientID=h.clientid
						join anfan_release.org.clients c on c.clientid_ff=cl.clientID
				)
				insert anfan_release.acc.fin_transactions (currencyid, transactiondate, detailsid, clientid, comment)
				output 
					inserted.transactionid, inserted.currencyid, inserted.transactiondate, inserted.detailsid, 
					inserted.clientid, inserted.comment into @transactions
				select  currencyid, transactiondate, detailsid, clientid, comment from s
				;

				/*make records to generalledger 10 entries per transaction*/
				with a (factor, accountid) as (
					select 1, null union all select -1, anfan_release.acc.accountid_func('зарплата к оплате', 'RUR')
				)
				, s (transactionid, entrydate, userid, accountid, contractorid, is_credit, journalid, amount) as (
					select 
						t.transactionid, @currenttime, 1,
						isnull(a.accountid, s.accountid),
						 case 
							when s.details in ('ЕСН', 'НДФЛ') and cl.clientid = 1 and a.accountid  is not null then 
									anfan_release.org.contractorid_func('УФК ПО Мос.Обл. (МЕЖ.РН. ИФНС РОССИИ №22 ПО МО)')
							when s.details in ('ЕСН', 'НДФЛ') and cl.clientid = 1003 and a.accountid  is not null then 
									anfan_release.org.contractorid_func('УФК МО (ИФНС Красногорск)')
							else c.contractorid end,
						(1 - a.factor)/2, s.journalid, s.amount
					from hr.salary_charge_f(@startdate, @update) s
						join anfan_release.org.clients cl on cl.clientid_ff=s.clientid
						join anfan_release.org.contractors c on personid_ff=s.personid
						join @transactions t on cast(SUBSTRING(t.comment,1, PATINDEX('%,%', t.comment)-1) as int)=c.contractorid
							and t.clientid=cl.clientid
						cross apply a 
					)
					insert anfan_release.acc.generalledger(transactionid, entrydate, userid, accountid, contractorid, is_credit, journalid, amount)
					output 
						inserted.entryid, inserted.transactionid, inserted.entrydate, inserted.userid, inserted.accountid,
						inserted.contractorid, inserted.is_credit, inserted.journalid, inserted.amount into @entries
					select transactionid, entrydate, userid, accountid, contractorid, is_credit, journalid, amount from s;

					update s set success= 'True', recorded_time =  @currenttime
					from hr.salary_dates s 
					where s.salary_date =@update;

			select @note = 'зарплата начислена'
			insert hr.salary_jobs_log values (@note, @currenttime)
			--;throw 50001, @note, 1;		
		commit transaction
	end try
	begin catch
		select @note = ERROR_MESSAGE ();
		rollback transaction
	end catch
