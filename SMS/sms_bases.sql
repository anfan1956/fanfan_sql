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

create table sms.customers (
	smsid int not null constraint fk_sms_instances_cust references sms.instances (smsid),
	customerid int not null constraint fk_sms_customers references cust.persons (personid),
	--no violetion of 3 normal, because customer phone could change, but ID stays
	phone char(10) not null,
	promocode char (6) NULL, 
	succsess bit, 
	constraint pk_sms_customeres primary key (smsid, customerid)
)

