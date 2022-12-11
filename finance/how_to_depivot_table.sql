use test
go
if OBJECT_ID('my_money') is not null drop table my_money
go
create table my_money (
	id int not null identity primary key,
	shop varchar (10) not null,
	amount money
)
go
insert my_money (amount, shop) values (1, 'wk'), (3, 'wk'), (5, 'ff'), (7, 'ff');
with _p (id, shop, m1, m2) as (
	select id, shop, amount, amount*2 
	from my_money

)
select id, shop	, qty, am from (
select * from _p) p
unpivot (qty for am in 
	(m1, m2)
	) as unpt


--example 2
if OBJECT_ID ('salary') is not null drop table salary
create table salary (
personid int,
com money, 
fix money

)

insert salary (personid, com, fix)
values 
	(1, 20, 30), 
	(2, 35, 40)
select * from salary;

select personid, amount, account from 
(
	select *
	from salary
) f
unpivot (amount for account in (com, fix)) as unp