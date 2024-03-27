if OBJECT_ID('hr.logAutorizations') is not null drop table hr.logAutorizations
go
create table hr.logAutorizations (
logid int not null identity primary key,
created datetime not null default current_timestamp,
userid int not null foreign key references org.users (userid), 
cashierid int not null foreign key references org.users (userid), 
amount money not null,
code char (5) not null,
articleid int not null foreign key references acc.articles (articleid),
used bit null

)
go

