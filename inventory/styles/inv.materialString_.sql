use fanfan
go


if OBJECT_ID('inv.materialString_') is not null drop function inv.materialString_
go
create function inv.materialString_ (@stRef int) returns varchar(max) as
begin
	declare @string varchar(max)
	select @string = STRING_AGG( '(''' + m.material + ''', ' +  format( cc.content*100, '#') + ')',   ', ' )
	from inv.styles s 
		join inv.compositionscontent cc on cc.compositionID =s.compositionID
		join inv.materials m on m.materialID=cc.materialID
	where s.styleID = @stRef
	return @string
end
go
declare @stRef int =20443, @st int = 20441
select inv.materialString_(@stRef)




