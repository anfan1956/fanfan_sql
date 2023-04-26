use fanfan
go

/*
cust.logs: на самом деле не относится к процедуре заказа товара напрямую
inv.site_reservations:  
	reservation - это transaction, поэтому для всех резервэйшнс есть foreign key к таблице inv.transactions
	в дальнейшем прикрепляется reservation_set
	резерв возникает при размещении заказа и будет 
		либо оплачен, после чего он превращается в заказ  - точнее в inv.sale
		либо отменен (cancelled) для чего автоматически создается другая транзакция (reservation cancellation)


*/

if OBJECT_ID('cust.logs') is not null drop table cust.logs
go
create table cust.logs (
personid int constraint fk_cust_logs foreign key  references cust.users (userid),
log_date datetime,
divisionid int not null constraint fk_cust_log_divisions foreign key references org.divisions (divisionid)
constraint pk_cust_logs primary key (personid, log_date, divisionid)
)
select personid, log_date, divisionid from cust.logs

if OBJECT_ID('inv.reservation_state_id') is not null drop function inv.reservation_state_id
if OBJECT_ID ('inv.site_reservations') is not null drop table inv.site_reservations
if OBJECT_ID ('inv.site_reserve_states') is not null drop table inv.site_reserve_states
create table inv.site_reserve_states (
	reservation_stateid int not null identity constraint pk_site_reserve_states primary key clustered, 
	reservation_state varchar (25) not null constraint uq_reservestate unique
 )
create table inv.site_reservations (
	reservationid int not null constraint pk_site_reservations primary key clustered
		constraint fk_reservations_transactions foreign key references inv.transactions(transactionid),
	custid int not null constraint fk_reservations_users foreign key references cust.persons (personid ), 
	expiration datetime not null,
	reservation_stateid int null constraint fk_reservations_reservationstates foreign key references inv.site_reserve_states(reservation_stateid), 
	saleid int null constraint fk_reservations_sales foreign key references inv.sales(saleid)
)
insert inv.site_reserve_states (reservation_state) values  ('active'), ('cancelled'), ('executed')
select * from inv.site_reserve_states; select * from inv.site_reservations

if object_id('inv.site_reservation_set') is not null drop table inv.site_reservation_set
if OBJECT_ID('inv.site_orders_states') is not null drop table inv.site_orders_states

create table inv.site_orders_states (
	order_stateid int not null identity constraint pk_site_order_states primary key,
	order_state varchar (25) not null constraint uq_site_order_states unique
 )

create table inv.site_reservation_set (
	reservationid int not null constraint fk_site_set_reservations foreign key references inv.transactions (transactionid),
	barcodeid int not  null constraint fk_rs_barcodes foreign key references inv.barcodes (barcodeid),
	price money not null,
	barcode_discount decimal (4,3) not null,
	promo_discount decimal (4,3) not null,
	amount money,
	constraint pk_site_reservationset primary key clustered (reservationid, barcodeid)
)

go
create function inv.reservation_state_id (@reservation_state varchar(25)) returns int as 
begin
	declare @stateid int;
		select @stateid= i.reservation_stateid  from inv.site_reserve_states  i where i.reservation_state = @reservation_state
	return @stateid
end
go



insert inv.site_orders_states values
('reserved'), 
('cancelled'), 
('paid'), 
('addressed'), 
('shipped'), 
('delivered'), 
('returned')

select * from inv.site_orders_states




select * from inv.transactiontypes order by 1 desc

