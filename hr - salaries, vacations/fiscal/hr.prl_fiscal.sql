if OBJECT_ID ('hr.prl_fiscal') is not null drop table hr.prl_fiscal
if OBJECT_ID ('hr.prl_pmttypes') is not null drop table hr.prl_pmttypes


go 
create table hr.prl_pmttypes(
	typeid int not null identity primary key,
	pmttype varchar(100) not  null unique
)


create table hr.prl_fiscal (
	empid int not null foreign key references org.users(userid), 
	clientid int not null foreign key references org.clients (clientid),
	bankid int not null foreign key references org.banks (bankid),
	accountNum char(20) not null,
	date_start date not null, 
	date_finish date null,
	primary key (empid, bankid, date_start)

)

insert hr.prl_pmttypes values ('Зарплата'), ('Аванс'), ('Отпускные'), ('Больничный')

insert hr.prl_fiscal(empid, clientid, bankid, accountNum, date_start)
	values 
		(47, 179, 585, '40817810400045705864', '20230901'), 
		(59, 179, 585, '40817810600045704911', '20230901'),
		(9, 619, 260,'40817810006200129691', '20230901'), 
		(10, 619, 260,'40817810706200129687', '20230901'), 
		(66, 619, 260,'40817810006360040733', '20230901')


if OBJECT_ID('hr.fiscalPaymentsList_') is not null drop function hr.fiscalPaymentsList_
go
create function hr.fiscalPaymentsList_(@date as date, @client as varchar(max)) returns table as return
with _maxdate as (  
	select top 1 дата 
	from rep.salaryReport_BEdate_f(getdate()) 
	where статья = 'НАЧИСЛЕНИЕ ЗАРПЛАТЫ'
	order by 1 desc
	)
select 
	p.lastname Фамилия, 
	p.firstname Имя, 
	p.middlename Отчество, 
	accountNum [Номер счета/Номер договора],
	round(s.сумма, 2) Сумма,
	case DATEPART(DD,@date)
		when 15 then 'Аванс'
		else 'Зарплата' end [Назначение платежа],
	1 [Код вида],
	0 [Удержанная сумма] 



from hr.prl_fiscal f
	join org.persons p on p.personID = f.empid
	cross apply _maxdate m
	join rep.salaryReport_BEdate_f(GETDATE()) s on s.personid=f.empid and cast(s.дата as date) = cast(m.дата as date)
where f.clientid= org.client_id_clientRUS(@client)
	and статья = 'НАЧИСЛЕНИЕ ЗАРПЛАТЫ' 
	and документ = 'bank'
go





declare @date date = '20231031'
	, @client varchar(max)= 'ПРОЕКТ Ф'
--	, @client varchar(max)= 'ИП ФЕДОРОВ'
select * from  hr.fiscalPaymentsList_(@date, @client)
;
select * from rep.salaryReport_BEdate_f (GETDATE()) s
where cast (s.дата as date) = @date
