
-- ***************************************---
if OBJECT_ID ('org.attendanceFull_p') is not null drop proc org.attendanceFull_p
go

create proc  org.attendanceFull_p 
			@date datetime
		,	@personID int 
		,	@workstationID int
		,	@delete bit = 'False'
as 
set nocount on;
set transaction isolation level read committed;
declare @msg varchar (max)
	begin try  
		begin transaction
			declare 
					@sTime TIME		= '10:00'
				,	@eTime TIME		= '22:00'

			delete a
			from org.attendance a
			where	a.workstationID				= @workstationID
				and	a.personID					= @personID
				and cast(a.checktime as date )	= @date;
		set @delete = isnull(@delete, 'False')
		if @delete = 'False'
		begin
			with _seed (checktype, checktime) as (
				select 1,  cast(@date as datetime) + cast(@sTime as datetime)
				union all 
				select 0,  cast(@date as datetime) + cast(@eTime as datetime)
			)
			insert org.attendance (personID, checktime, checktype, workstationID, superviserID)
			select @personID, s.checktime, s.checktype, @workstationID, 1 superviserID
			from _seed s;
		end
	--	;throw 50001, 'debuging' , 1 
		select @msg = @@ROWCOUNT
		select @msg msg
		commit transaction
	end try

	begin catch
		select @msg = ERROR_MESSAGE()
		select @msg
		rollback transaction
	end catch
go 


declare 
	@date datetime = '20241022' 
	, @personid int = 1078 
	, @workstationID int = 14
	, @delete bit = 'False'

;select a.*, p.lfmname 
from org.attendance a
	join org.persons p on p.personID =a.personID 
where cast(a.checktime as date) = @date

/*
exec org.attendanceFull_p 
		@date 		= @date	
	, 	@personID	= @personID
	,	@workstationID  = @workstationID
	,	@delete  = @delete
;
*/
;select a.*, p.lfmname 
from org.attendance a
	join org.persons p on p.personID =a.personID 
where cast(a.checktime as date) = @date        
