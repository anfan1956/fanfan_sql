use fanfan
go

if OBJECT_ID('fin.other_expenses')  is not null drop table fin.other_expenses
if OBJECT_ID('fin.other_exense_types') is not null drop table fin.other_exense_types
go
create table fin.other_exense_types(
	expense_typeid int not null identity  constraint pk_expense_types primary key,
	expense_type varchar(25) not null constraint uq_expense_types unique
)
go
create table fin.other_expenses (
	expenseid int not null identity constraint pk_other_expenses primary key, 
	expense_typeid int not null constraint fk_other_expenses_types foreign key references fin.other_exense_types (expense_typeid), 
	amount money not null, 
	date_start date not null,
	date_end date null,
	details varchar (150) not null, 
	day_due int not null,
	constraint uq_other_expense_types unique (expense_typeid, details, date_start, day_due)
)
go
insert fin.other_exense_types (expense_type) values 
('FIXED_PRLL'), 
('BANK INT'), 
('PRIVATE LOANS'),
('OTHER')

select * from fin.other_exense_types
if OBJECT_ID('fin.other_expensetype_id') is not null drop function fin.other_expensetype_id
go
create function fin.other_expensetype_id (@expense_type varchar(25)) returns int as 
begin
	declare @expense_typeid int;
		select @expense_typeid = expense_typeid from fin.other_exense_types where expense_type= @expense_type;
	return @expense_typeid;
end
go
select fin.other_expensetype_id('OTHER');

insert fin.other_expenses (expense_typeid, amount, date_start, details, day_due) values
(fin.other_expensetype_id('FIXED_PRLL'), 35000, '20220101', 'Зара Пикулевой', 10), 
(fin.other_expensetype_id('FIXED_PRLL'), 35000, '20220101', 'Зара Пикулевой', 25), 
(fin.other_expensetype_id('FIXED_PRLL'), 10000, '20220101', 'Зара Петрова', 10), 
(fin.other_expensetype_id('FIXED_PRLL'), 10000, '20220101', 'Зара Петрова', 25), 
(fin.other_expensetype_id('FIXED_PRLL'), 35000, '20220101', 'Зара Неверова', 10), 
(fin.other_expensetype_id('FIXED_PRLL'), 35000, '20220101', 'Зара Неверова', 25), 
(fin.other_expensetype_id('FIXED_PRLL'), 80000, '20220101', 'Зара Федорова', 10), 
(fin.other_expensetype_id('FIXED_PRLL'), 80000, '20220101', 'Зара Федорова', 25), 
(fin.other_expensetype_id('BANK INT'), 35000, '20220101', 'Альфа по первым числам', 1), 
(fin.other_expensetype_id('BANK INT'), 77000, '20220101', 'Альфа по шестым числам', 6), 
(fin.other_expensetype_id('BANK INT'), 25000, '20220101', 'Альфа кредитка по 21 числам', 21), 
(fin.other_expensetype_id('BANK INT'), 25000, '20220101', 'СИТИБАНК по 12 числам', 12), 
(fin.other_expensetype_id('BANK INT'), 48250, '20220101', 'МКБ по 24 числам', 24), 
(fin.other_expensetype_id('BANK INT'), 17300, '20220101', 'Тиньков по 20 числам', 20), 
(fin.other_expensetype_id('PRIVATE LOANS'), 35000, '20220101', 'Лунев по 18 числам, в евро', 18)

select *, sum(o.amount) over ()
from fin.other_expenses o