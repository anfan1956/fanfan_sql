IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'errorLogs' AND s.name = 'cmn'
)

--if OBJECT_ID('cmn.errorLogs') is not null drop table cmn.errorLogs
create table cmn.errorLogs (
	logid int not null identity primary key, 
	logtime datetime default current_timestamp,
	schemaName	varchar(255) not null ,
	functionName varchar(255) not null ,
	workstationid int null foreign key references org.workstations (workstationid), 
	errorMessage varchar(max)
)

