if OBJECT_ID('inv.nextBox_') is not null drop function inv.nextBox_
go 
create function inv.nextBox_ () returns int as 
	begin
		declare @nextId INT;
			select  top 1 @nextId =  i 
			from cmn.numbers n 
			outer apply (
					select top 1 sb.boxID
					from inv.storage_box sb
					order by 1 desc
				) sb
			where i > coalesce(sb.boxID, 0)
			order by i 
			RETURN @nextID
	end
go

select inv.nextBox_()


select * from inv.storage_box