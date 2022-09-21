use test 
go

if OBJECT_ID('orders_barcodes') is not null drop table orders_barcodes
if OBJECT_ID('orders') is not null drop table orders
if OBJECT_ID('vendor_brands') is not null drop table vendor_brands
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


CREATE TABLE vendor_brands (
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

--select * from brands
--select * from vendors
--select * from barcodes
--select * from orders

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
select * from orders_v