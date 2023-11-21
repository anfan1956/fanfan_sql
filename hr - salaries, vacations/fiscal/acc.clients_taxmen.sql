if OBJECT_ID('acc.clients_taxmen') is not null drop table acc.clients_taxmen
go

create table acc.clients_taxmen (
	clientid int not null foreign key references org.clients (clientid), 
	taxmanid int not null foreign key references org.contractors (contractorid), 
	datestart date not null, 
	primary key (clientid, taxmanid, datestart)
)


insert acc.clients_taxmen (clientid, taxmanid, datestart) 
values (179, 1678, '20230101')

select * from acc.clients_taxmen
