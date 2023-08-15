
if OBJECT_ID('cmn.buttons') is not null drop table cmn.buttons
if OBJECT_ID('cmn.worksheets') is not null drop table cmn.worksheets
if OBJECT_ID('cmn.buttonText') is not null drop table cmn.buttonText
if OBJECT_ID('cmn.buttonSub') is not null drop table cmn.buttonSub

create table cmn.worksheets(
	worksheetid int not null identity  primary key, 
	wsname varchar (50) not null
)

create table cmn.buttonText(
	textid int not null identity  primary key, 
	buttonTtext varchar (50) not null
)
create table cmn.buttonSub(
	subid int not null identity  primary key, 
	subName varchar (50) not null
)

go 
create table cmn.buttons (
	buttonid int not null identity primary key,
	worksheetid int not null foreign key references cmn.worksheets (worksheetid),
	textid int not null foreign key references cmn.buttonText (textid),
	subid  int not null foreign key references cmn.buttonSub (subid),
	button_scope_full bit not null default (1)
)



insert cmn.worksheets values ('пивот зарплата')

insert cmn.buttonText values 
	('удалить начисление'), 
	('на главную'), 
	('отчет: зарплата'), 
	('зарплата: нач. остатки'), 
	('остатки и платежи (Al-Cl-F10)')  

insert cmn.buttonSub values 
	('удалить начисление'), 
	('на главную'), 
	('отчет: зарплата'), 
	('зарплата: нач. остатки'), 
	('остатки и платежи (Al-Cl-F10)')  

select * from cmn.buttons
insert cmn.buttons(worksheetid, textid, subid) values 
	(1, 1, 1), 
	(1, 2, 2), 
	(1, 3, 3), 
	(1, 4, 4), 
	(1, 5, 5) 

select * from cmn.worksheets
select * from cmn.buttons
select * from cmn.buttonSub
select * from cmn.buttonText