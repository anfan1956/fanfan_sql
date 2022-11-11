use fanfan
go

throw 50001, 'working tables. Cannot run', 1;

if OBJECT_ID('pmt.payment_orders') is not null drop table pmt.payment_orders
if OBJECT_ID('pmt.orderspayment_types') is not null drop table pmt.orderspayment_types

create table pmt.orderspayment_types (
	typeid int not null identity constraint pk_orders_pmt_types primary key, 
	type varchar (25) not null constraint uq_orders_pmt_types unique
)


if OBJECT_ID('pmt.orderspayments') is not null drop table pmt.orderspayments
if OBJECT_ID('pmt.registers') is not null drop table pmt.registers
create table pmt.registers (
	registerid int not null identity constraint pk_pmt_registers primary key,
	bankid int not null constraint fk_pmt_registers_banks foreign key references org.banks (bankid),
	currencyid int not null constraint fk_pmt_registers_currencies foreign key references cmn.currencies (currencyid),
	account varchar (24) null constraint uq_pmt_registers_account unique,
	bankcard varchar (20) null  constraint uq_pmt_registers_card unique
)

create table pmt.orderspayments (
	paymentid int not null identity constraint pk_orders_pmts primary key, 
	pmtdate date not null, 
	vendorid int not null constraint fk_orders_payments foreign key references org.vendors (vendorid),
	registerid int not null constraint fk_orderspayments_registers references pmt.registers (registerid)
)

create table pmt.payment_orders (
	paymentid int not null constraint fk_pmt_pmt_orders foreign key references pmt.orderspayments (paymentid),
	orderid int not null constraint  fk_pmt_orders foreign key references inv.orders (orderid),
	typeid int not null  constraint  fk_pmt_pmttypes foreign key references pmt.orderspayment_types (typeid),
	amount money not null
)

