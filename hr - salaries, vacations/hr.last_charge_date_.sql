if OBJECT_ID('hr.last_charge_date_') is not null drop function hr.last_charge_date_
go 
create function hr.last_charge_date_ () returns varchar(max) as 
begin
declare @date varchar(max)


	select top 1 @date =  FORMAT(дата, 'yyyyMMdd')
	from rep.salaryReport_BEdate_f(getdate()) 
	where статья = 'НАЧИСЛЕНИЕ ЗАРПЛАТЫ'
	order by дата desc

return @date
end
go

select  hr.last_charge_date_()


