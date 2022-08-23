USE fanfan
GO
/*
Цель - создать таблицы, которые помогут расчитать взаимоотношения 
с поставщиками, а также себестоимость товара
для этого создаем директорию ap от accounts payable
*/
if OBJECT_ID('ap.charges_barcodes')is not null drop table ap.charges_barcodes 
if OBJECT_ID('ap.charges')is not null drop table ap.charges 
if OBJECT_ID('ap.chargetypes')is not null drop table ap.chargetypes 

create table ap.chargetypes(
	typeid_charged int not null identity constraint pk_chargetypes primary key,
	type_charged VARCHAR (25) NOT NULL CONSTRAINT uq_chargetype UNIQUE
)
if OBJECT_ID('ap.doctypes')is not null drop table ap.doctypes 
create table ap.doctypes(
	typeid_doc int not null identity constraint pk_doctypes primary key,
	type_doc VARCHAR (25) NOT NULL CONSTRAINT uq_doctype UNIQUE
)

create table ap.charges(
	chargeid int not null identity constraint pk_charges primary key,
	date_charged DATETIME NOT NULL,
	typeid_charged INT NOT NULL CONSTRAINT fk_charges_chargetypes FOREIGN KEY REFERENCES ap.chargetypes (typeid_charged),
	vendorid INT NOT NULL CONSTRAINT fk_chargess_vendors FOREIGN KEY REFERENCES org.vendors (vendorid),
	clientid INT NOT NULL CONSTRAINT fk_charges_clients FOREIGN KEY REFERENCES org.clients (clientID),
	currencyid INT NOT NULL CONSTRAINT fk_charges_currency FOREIGN KEY REFERENCES cmn.currencies (currencyID),
	doctypeid INT NOT NULL CONSTRAINT fk_charges_doctypes FOREIGN KEY REFERENCES ap.doctypes (typeid_doc), 
	document VARCHAR (100) null
)
INSERT ap.chargetypes (type_charged)
VALUES 
('FOB'), 
('FOB logistics'), 
('freight'), 
('customs'),  -- all the customs procedures excl duties and VAT
('duties'), 
('DDP logistics'),
('marking');
SELECT * FROM ap.chargetypes c ORDER BY 1



create table ap.charges_barcodes(
	chargeid INT NOT NULL CONSTRAINT fk_charges_barcodes_charges FOREIGN KEY REFERENCES ap.charges (chargeid),
	barcodeid INT NOT NULL CONSTRAINT fk_charges_barcodes_barcodes FOREIGN KEY REFERENCES inv.barcodes (barcodeid),
	CONSTRAINT pk_charges_barcodes PRIMARY KEY CLUSTERED (chargeid, barcodeid)
)

if OBJECT_ID('ap.payments')is not null drop table ap.payments 
if OBJECT_ID('ap.registers')is not null drop table ap.registers 
if OBJECT_ID('ap.reg_types')is not null drop table ap.reg_types 

create table ap.reg_types(
	reg_typeid int not null identity constraint pk_reg_types primary key,
	reg_type VARCHAR (25) NOT NULL CONSTRAINT uq_regtype UNIQUE
)
INSERT ap.reg_types(reg_type) 
VALUES 
('till'), 
('safe'), 
('bank'), 
('card');
SELECT * FROM ap.reg_types rt ORDER BY 1

create table ap.registers(
	registerid int not null identity constraint pk_registers primary key,
	reg_typeid INT NOT NULL,
	currencyid INT NOT NULL, 
	reg_bankerid INT NOT NULL
)

create table ap.payments(
	paymentid int not null identity constraint pk_payments primary key,
	registerid INT NOT null
)