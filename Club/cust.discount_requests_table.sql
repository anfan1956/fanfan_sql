USE fanfan
GO

if OBJECT_ID('cust.disount_requests')is not null drop table cust.disount_requests 

create table cust.disount_requests(
	requestid int not null identity constraint pk_disount_requests primary key,
	request_time DATETIME, 
	request_typeid INT NOT NULL, 
	userid INT NOT NULL,
	customerid INT NOT NULL, 
	barcodeid INT NOT NULL, 
	approved bit

)