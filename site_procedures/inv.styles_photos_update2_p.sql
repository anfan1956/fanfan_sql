USE [fanfan]
GO
/****** Object:  StoredProcedure [inv].[styles_photos_update2_p]    Script Date: 02.05.2024 23:20:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc  [inv].[styles_photos_update2_p]  @photo_filename dbo.idvar_type readonly as
begin try	
	begin transaction;
		declare @r int;
		declare @styleid table (the_action varchar (10), styleid int);
		with s (styleid, photo_filename, barcodeid, parent_styleid) as (
			select b.styleID, p.var1, p.id, s.parent_styleid
			from @photo_filename p
				join inv.barcodes b on b.barcodeID=p.id
				join inv.styles s on s.styleID=b.styleID
			)
		merge inv.styles_photos as t using s
		on t.styleid=s.styleid and t.photo_filename=s.photo_filename
		when matched then update 
			set t.barcodeid=s.barcodeid, 
			t.parent_styleid=s.parent_styleid
		when not matched then 
			insert (styleid, photo_filename, barcodeid, parent_styleid)
			values (styleid, photo_filename, barcodeid, parent_styleid)
			output $action, inserted.styleid into @styleid;
			select @r = count(styleid) from @styleid where the_action ='INSERT'; 

		update p set p.receipt_date =d.receipt_date
		from inv.styles_photos p 
			join inv.style_clearance_dates_v d on d.styleid=p.styleid
	commit transaction 
	return @r

end try
begin catch
	rollback transaction
	return -1
end catch
go
