use test 
go
if OBJECT_ID('payments_invoices') is not null drop table payments_invoices
if OBJECT_ID('payments') is not null drop table payments
if OBJECT_ID('invoices_orders') is not null drop table invoices_orders
if OBJECT_ID('invoices') is not null drop table invoices
if OBJECT_ID('orders_barcodes') is not null drop table orders_barcodes
if OBJECT_ID('orders') is not null drop table orders
if OBJECT_ID('vendors_brands') is not null drop table vendors_brands
if OBJECT_ID('vendors') is not null drop table vendors
if OBJECT_ID('brands') is not null drop table brands
if OBJECT_ID('inv_types') is not null drop table inv_types
if OBJECT_ID('barcodes') is not null drop table barcodes


CREATE TABLE vendors (
vendorid int not null identity primary key, 
vendor varchar(30) not null
)

CREATE TABLE brands (
brandid int not null identity primary key, 
brand varchar(30) not null
)

CREATE TABLE inv_types (
inv_typeid int not null identity primary key, 
inv_type varchar(30) not null
)

CREATE TABLE barcodes (
barcodeid int not null identity primary key, 
cost money not null
)


CREATE TABLE vendors_brands (
vendorid int not null foreign key references vendors(vendorid), 
brandid int not null foreign key references brands(brandid),
constraint pk_vb primary key (vendorid, brandid) 
)


CREATE TABLE orders (
	orderid int not null identity primary key, 
	date datetime not null,
	vendorid int not null,
	brandid int not null

)

CREATE TABLE orders_barcodes (
	orderid int not null foreign key references orders (orderid),
	barcodeid int not null foreign key references barcodes (barcodeid), 
	primary key (orderid, barcodeid)
)

CREATE TABLE invoices (
	invoiceid int not null identity primary key, 
	vendorid int not null foreign key references vendors (vendorid),
	inv_typeid int not null foreign key references inv_types (inv_typeid)
)

CREATE TABLE invoices_orders (
	invoiceid int not null foreign key references invoices (invoiceid),
	orderid int not null foreign key references orders (orderid),
	amount money not null, 
	primary key (invoiceid, orderid)

)

CREATE TABLE payments (
	paymentid int not null identity primary key, 
	vendorid int not null foreign key references vendors (vendorid)
)

CREATE TABLE payments_invoices (
	paymentid int not null foreign key references payments (paymentid),
	invoiceid int not null foreign key references vendors (vendorid), 
	amount money not null
)



------------------------------------------------
if OBJECT_ID('orders_v') is not null drop view orders_v
go
create view orders_v as
	select 
		o.orderid,
		sum(b.cost) cost,  brand, vendor
	from orders o 
		join orders_barcodes ob on ob.orderid = o.orderid
		join barcodes b on b.barcodeid=ob.barcodeid
		join brands br on br.brandid = o.brandid
		join vendors v on v.vendorid = o.vendorid
	group by brand, vendor, o.orderid
go

insert brands (brand) values 
('Aeronautica'), ('James Perse'), ('Parajumpers'), ('Ballantyne'), ('One TeaSpoon')

insert vendors (vendor) values 
('Cristiano DT'), 
('Vittorio EM'), 
('Allen Group It') 


insert barcodes(cost) values 
(50),  
(22),  
(32),  
(48),  
(58),  
(38),  
(63),  
(55),  
(52),  
(61),  
(65),  
(38),  
(40),  
(40),  
(60),  
(32),  
(42),  
(62)

insert orders (date, vendorid, brandid) values 
( '20220914', 1, 3), 
( '20220915', 1, 5) 

insert orders_barcodes (orderid, barcodeid) values 
(1, 1), 
(1, 2), 
(1, 3), 
(1, 4), 
(1, 5), 
(1, 6), 
(1, 7), 
(1, 8), 
(1, 9), 
(2, 10), 
(2, 11), 
(2, 12), 
(2, 13), 
(2, 14), 
(2, 15), 
(2, 16), 
(2, 17), 
(2, 18) 

insert inv_types (inv_type) values 
('proforma'),
('deposit')

insert invoices (vendorid, inv_typeid) values
(1, 2), 
(1, 1) 

insert invoices_orders(invoiceid, orderid, amount) values
(1, 1,20) 

insert payments (vendorid) values
(1) 

insert vendors_brands (vendorid, brandid) values
(2, 3), 
(2, 5), 
(1, 1), 
(3, 2) 

insert payments_invoices (paymentid, invoiceid, amount) values
(1, 1, 15)

select * from invoices
select * from orders_barcodes
select * from inv_types
select * from vendors
select * from payments
select * from invoices_orders
select * from orders
select * from vendors_brands
select * from payments_invoices
select * from brands
select * from barcodes
select * from orders_v

select 
	i.invoiceid, v.vendor, t.inv_type, io.amount, 
	sum (b.cost) order_amount
from invoices i
	join vendors v on v.vendorid=i.vendorid
	join inv_types t on t.inv_typeid= i.inv_typeid
	join invoices_orders io on io.invoiceid=i.invoiceid
	join orders o on o.vendorid = i.vendorid  and o.orderid= io.orderid
	join orders_barcodes ob on ob.orderid=ob.orderid
	join barcodes b on b.barcodeid=ob.barcodeid
	left join payments p on p.vendorid=i.vendorid
group by i.invoiceid, v.vendor, t.inv_type, io.amount 
