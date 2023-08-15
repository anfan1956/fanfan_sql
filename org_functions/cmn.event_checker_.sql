if OBJECT_ID('cmn.event_checker_') is not null drop function cmn.event_checker_
go 
create function cmn.event_checker_() returns varchar(max) as 
begin
	declare @checker varchar(max);
		
		with isales (saleid) as (
			select saleid from inv.sales
			except select saleid from web.sales_log
		)
		,s as (
			select top 1 s.saleID, format(sum(sg.amount), '# ##0 руб' ) сумма, count(sg.amount) штук,  
				format(t.transactiondate, 'HH;mm') время 
		from inv.sales s			
			join isales sa on sa.saleid=s.saleID
			join inv.transactions t on t.transactionID=s.saleID
			join inv.sales_goods sg on sg.saleID= s.saleID


		where s.divisionID=org.division_id('FANFAN.STORE')
		group by t.transactiondate, s.saleID
		)
		select @checker = (select* from s 
		order by 1 desc
		for json path
		)
	return @checker
end 
go


if OBJECT_ID('web.sales_log') is not null drop table web.sales_log
go
create table web.sales_log (
	logid int not null identity primary key,
	saleid int not null foreign key references inv.sales (saleid)

)


	
if OBJECT_ID ('web.check_sales_') is not null drop proc web.check_sales_
go
create proc web.check_sales_
	@checker varchar(max) output		
as 
set nocount on; 
	select @checker = cmn.event_checker_()
	declare @r int;
	with isales (saleid) as (
		select t.transactionID saleid
			from inv.transactions t
			where t.transactiontypeID= inv.transactiontype_id('ON_SITE SALE')	
		except
			select saleid
			from web.sales_log 
		)
	, s as (
		select top 1 saleid from isales
		)
	merge web.sales_log as t using  s
	on t.saleid = s.saleid
	when not matched then 
	insert values (s.saleid);
	select @r = @@ROWCOUNT;
	

		if ( @r =0) 

			select @checker = 'no sales'

go

set nocount on; declare @checker varchar(max); 
select cmn.event_checker_()
--exec web.check_sales_ @checker output; select @checker;
select * from web.sales_log;





