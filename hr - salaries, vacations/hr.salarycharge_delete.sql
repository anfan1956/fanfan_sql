if OBJECT_ID('hr.salarycharge_delete') is not null drop proc hr.salarycharge_delete
go
create proc hr.salarycharge_delete
	@note varchar(max) output, 
	@salary_date date
as
set nocount on;
	begin try
		begin transaction

		declare @transactions table (transactionid int);
		insert @transactions select t.transactionid from acc.transactions t 
		where t.transdate= @salary_date
			and t.articleid = acc.article_id('Начисление зарплаты')
		if (select count(*) from @transactions) = 0  
			begin
				select @note = 'зарплатa от ' + format(@salary_date, 'dd.MM.yyyy')  + ' не начислена';
				throw 50001, @note, 1;
			end

		delete e from acc.entries e join @transactions t on t.transactionid=e.transactionid;
		delete e from acc.transactions e join @transactions t on t.transactionid=e.transactionid;
		delete p from hr.periodCharges p where p.periodEndDate = @salary_date;
		update s set success= null, recorded_time = null from hr.salary_dates s where s.salary_date=@salary_date;
		insert hr.salary_jobs_log (result, logtime, salary_date) select 'начисление анулировано', CURRENT_TIMESTAMP, @salary_date

		select @note = 'начисление зарплаты от ' + format(@salary_date, 'dd.MM.yyyy')  + ' удалено';
		--throw 50001, @note, 1;
		commit transaction
	end try
	begin catch
		set @note = ERROR_MESSAGE()
		rollback transaction
	end catch
go

declare @salary_date date = '2023-03-31'
--declare @note varchar(max); exec hr.salarycharge_delete @note output, @salary_date;select @note


