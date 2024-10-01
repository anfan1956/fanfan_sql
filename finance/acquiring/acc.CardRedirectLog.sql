if OBJECT_ID('acc.CardRedirectLog') is not null drop table acc.CardRedirectLog

create table acc.CardRedirectLog (
	ID int not null identity Primary key, 
	logtTme smalldatetime default current_timestamp,
	transactionId int not null foreign key references inv.sales (saleid), 
	closedTime smalldatetime null, 
	receiptID int null, 
	fiscalId varchar(255) null
)
select * from acc.CardRedirectLog