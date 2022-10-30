use fanfan
go

if OBJECT_ID ('sms.instances_sales') is not null drop table sms.instances_sales
go
CREATE TABLE sms.instances_sales (
-- will have to correct the sales procedure
	saleid int not null constraint fk_sms_instance_sales_sales foreign key references inv.sales (saleid),
	smsid int not null constraint fk_sms_instance_sales_sms foreign key references sms.instances (smsid), 
	constraint pk_instances_sales primary key (saleid, smsid)
)