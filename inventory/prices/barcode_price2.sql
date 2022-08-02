USE [fanfan]
GO
/****** Object:  UserDefinedFunction [inv].[barcode_price2]    Script Date: 02.08.2022 16:38:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [inv].[barcode_price2](@barcodeid int, @user varchar(37)) returns money as 
begin
	declare @response money;
	declare @output money;
	declare @division table (divisionid int, checktype bit);

	with _division as (
			select  top 1 w.divisionid, checktype
			from org.attendance a
				join org.users u on u.userID=a.personID
				join org.persons p on p.personID=u.userID
				join org.workstations_divisions_current_v w on w.workstationid=a.workstationID
			where p.lfmname=@user and cast(a.checktime as date)=cast(CURRENT_TIMESTAMP as date)		
			order by checktime desc
	)
	insert @division select * from _division;

select @output =  f.cost * r.rate * r.markup
from inv.current_rate_v r
	join @division d on d.divisionid= r.divisionid and d.checktype='True'
	join org.divisions s on d.divisionid = s.divisionid
	join inv.barcode_cost_f (@barcodeid) f on f.currencyID = r.currencyid
	join inv.v_remains v on v.barcodeID=f.barcodeID and v.divisionID=d.divisionid
	;
 
if @output is not null
	select @response = @output;
return @response
end
