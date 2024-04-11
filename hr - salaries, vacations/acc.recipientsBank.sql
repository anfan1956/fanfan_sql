if OBJECT_ID('acc.recipientsBank') is not null drop table acc.recipientsBank
go
create table acc.recipientsBank (
	userid int not null foreign key references org.users (userid),
	dateStart date not null,
	bankid int null references org.banks (bankid),
	primary key (userid, datestart)
)

--select b.*, c.contractor from org.banks b join org.contractors c on c.contractorID=b.bankID
--select * from org.users where phone is not null
declare @date date = '20240101', @paydate date = '20240410'

insert acc.recipientsBank (userid, dateStart, bankid)
values 
(1075, @date, null), 
(1074, @date, 638), 
(7, @date, 638), 
(9, @date, 638), 
(1077, @date, 638)


select u.username, c.contractor bank
from acc.recipientsBank r
	join org.users u on u.userID=r.userid
	join org.contractors c on c.contractorID=isnull(r.bankid, org.contractor_id('ИП Федоров'))

;

if OBJECT_ID('acc.empCurrentBank_') is not null drop function acc.empCurrentBank_
go
create function acc.empCurrentBank_(@date date) returns table as return
with _banks (userid, bankid, num) as (
	select 
		r.userid, isnull(r.bankid,org.contractor_id('ИП Федоров')),
		ROW_NUMBER () over (partition by r.userid order by r.dateStart desc)
	from acc.recipientsBank r 
	where dateStart <= @date
)
select userid, bankid from _banks

go
declare @date date = '20240101', @paydate date = '20240410'
select * from acc.empCurrentBank_(@date)

select phone, s.userID, lastname, firstname, middlename, amount, c.contractor rcptBank
from hr.SBER_template_('20240331', 'cash')  s
	left join acc.empCurrentBank_(getdate()) cu on cu.userid=s.userID
	left join org.contractors c on c.contractorID=isnull(cu.bankid, org.contractor_id('ТИНЬКОФФ'))

select * from org.users u order by 1 desc