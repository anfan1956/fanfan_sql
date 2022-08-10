use fanfan
go

if OBJECT_ID('sms.instances_customers') is not null drop table sms.instances_customers
if OBJECT_ID('sms.instances') is not null drop table sms.instances
go 
create table sms.instances (
	smsid int not null identity constraint pk_sms_instances primary key,
	smstext varchar (255) not null, 
	smsdate datetime not null default current_timestamp,
	senderid int not null constraint fk_sms_client foreign key references org.clients (clientid), 
	userid int not null constraint fk_sms_users foreign key references org.users (userid), 
	singlePromo BIT DEFAULT ('True'), 
	expirationDate DATE NOT NULL, 
	discount DECIMAL(4,3) NULL
)

create table sms.instances_customers (
	smsid int not null constraint fk_sms_instances_cust references sms.instances (smsid),
	customerid int not null constraint fk_sms_customers references cust.persons (personid),
	--no violation of 3 normal, because customer phone could change, but ID stays
	promocode char (4) NULL, 
	cost MONEY,
	constraint pk_sms_customeres primary key (smsid, customerid)
)


