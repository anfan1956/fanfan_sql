use fanfan
go

if OBJECT_ID('sms.customers') is not null drop table sms.customers
if OBJECT_ID('sms.instances') is not null drop table sms.instances
go 
create table sms.instances (
	smsid int not null identity constraint pk_sms_instances primary key,
	smstext varchar (255) not null, 
	smsdate datetime not null default current_timestamp,
	cost money not null,
	senderid int not null constraint fk_sms_client foreign key references org.clients (clientid), 
	userid int not null constraint fk_sms_users foreign key references org.users (userid), 
	singlePromo BIT DEFAULT ('True'), 
	expirationDate DATE NOT NULL, 
	discount DECIMAL(4,3) NOT NULL
)

if OBJECT_ID('sms.messages')is not null drop table sms.messages 

create table sms.messages(
	messageid int not null identity constraint pk_messages primary key,
	message VARCHAR (1000)
)

if OBJECT_ID('sms.operator_costs')is not null drop table sms.operator_costs 


if OBJECT_ID('sms.operators')is	 not null drop table sms.operators 

create table sms.operators(
	operatorid int not null identity constraint pk_operators primary key,
	operator VARCHAR (25) CONSTRAINT uq_operator UNIQUE
)

create table sms.operator_costs(
	operatorid int not null identity constraint pk_operator_costs primary key,
	cost MONEY NOT NULL,
	recorded DATETIME DEFAULT(CURRENT_TIMESTAMP)
)

INSERT sms.operators (operator) VALUES ('Билайн'), ('МТС'), ('Мегафон'), ('Теле2'	)
SELECT * FROM sms.operators o


create table sms.customers (
	smsid int not null constraint fk_sms_instances_cust references sms.instances (smsid),
	customerid int not null constraint fk_sms_customers references cust.persons (personid),
	--no violation of 3 normal, because customer phone could change, but ID stays
	phone char(10) not null,
	mesID INT NULL CONSTRAINT fk_customers_messages FOREIGN KEY REFERENCES sms.messages(messageid),
	promocode char (6) NULL, 
	succsess bit, 
	constraint pk_sms_customeres primary key (smsid, customerid)
)


