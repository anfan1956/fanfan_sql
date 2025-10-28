use fanfan
go
-- ***************************************---
if OBJECT_ID ('org.attendanceFull_p') is not null drop proc org.attendanceFull_p
go

create proc  org.attendanceFull_p 
			@date datetime
		,	@personID int 
		,	@workstationID int
		,	@delete bit = 'False'
		,   @full bit = 'True'
as 
set nocount on;
set transaction isolation level read committed;
declare @msg varchar (max)
	begin try  
		begin transaction
			declare 
					@sTime TIME		= '10:00'
				,	@eTime TIME		= '22:00'
				if org.ws_divisionName( @workstationID) =  '07 УИКЕНД'
					begin
						set @sTime = '12:00'
						set @eTime = '20:00'
					end 
			delete a
			from org.attendance a
			where	a.workstationID				= @workstationID
				and	a.personID					= @personID
				and cast(a.checktime as date )	= @date;
		set @delete = isnull(@delete, 'False')
		set @full  = ISNULL(@full, 'True')
		if @delete = 'False'
		begin

				insert org.attendance (personID, checktime, checktype, workstationID, superviserID)
				select @personID, cast (@date as datetime) + cast(@sTime as datetime), 1, @workstationID, 1 superviserID
				select @@ROWCOUNT rowsInserted
			if @full = 'TRUE' 
				begin 
					insert org.attendance (personID, checktime, checktype, workstationID, superviserID)
					select @personID, cast (@date as datetime) + cast(@eTime as datetime), 0, @workstationID, 1 superviserID
				end 
		end
	--	;throw 50001, 'debuging' , 1 
		select @msg = @@ROWCOUNT
		select convert(varchar,  @msg)  + ' строк редактировано' msg
		commit transaction
	end try

	begin catch
		select @msg = ERROR_MESSAGE()
		select @msg
		rollback transaction
	end catch
go 


declare 
	@date datetime = '20251027'
	, @personid int = 5
	 
	, @workstationID int = 23
	, @delete bit = 'False'
	, @full bit		= 'False'

;select a.*, p.lfmname 
from org.attendance a
	join org.persons p on p.personID =a.personID 
where cast(a.checktime as date) = @date
/*
exec org.attendanceFull_p @date = @date, @personID	= @personID, @workstationID  = @workstationID, @delete  = @delete, @full = @full;
*/



;select a.*, p.lfmname 
from org.attendance a
	join org.persons p on p.personID =a.personID 
where cast(a.checktime as date) = @date        
;

