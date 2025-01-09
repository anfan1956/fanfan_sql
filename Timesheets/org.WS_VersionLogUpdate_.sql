select * from org.versionLogs

If OBJECT_ID('org.WS_VersionLogUpdate_') is not null drop proc org.WS_VersionLogUpdate_
go 

create proc org.WS_VersionLogUpdate_ @workstation as varchar(max) 
	
-- this proc is used only when RDP updated the timesheets and need to update the logs
as
begin try
set nocount on;
	
	declare 
		@currentVersionNum int, 
		@workstationid int 
		set @workstationid = org.workstation_id(@workstation);
	
	select 
		@currentVersionNum = v.timesheetsversionID 
	from cmn.versions v
	where  v.working_file = 'timesheets.xlsm'
	insert org.versionLogs(workstationid, versionNumber, userid)
	select 
		@workstationid 
		, @currentVersionNum 
		, org.user_id('INTERBOT')
	
end try 
begin catch
		insert cmn.errorLogs
			(
				  schemaName
				, functionName
				, workstationid
				, errorMessage 
			)
		select 
			 OBJECT_SCHEMA_NAME(@@PROCID) AS SchemaName
			, OBJECT_NAME(@@PROCID) AS FunctionName
			, @workstationid
			, ERROR_MESSAGE()		
end catch

go

declare 
	@ws varchar(max) = 'WEEKEND07';

--exec org.WS_VersionLogUpdate_  @ws
select * from cmn.errorLogs