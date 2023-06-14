declare @months int = 3, @json varchar(max); 


if OBJECT_ID('inv.arrivals_json') is not null drop function inv.arrivals_json
go

create function inv.arrivals_json(@months as int) returns varchar(max) as
	begin
		declare @arrivals varchar(max);
			with s as (
				select iif(gender = '', 'УНИ', gender) gender, brand, category, article, styleid, photo_filename, receipt_date, price, discount 
				from inv.styles_catalog_v where receipt_date >= DATEADD(mm, -@months, CURRENT_TIMESTAMP)
			)
			select @arrivals = 
				(select s.styleid модель, s.brand, s.category, s.price, s.discount, format(receipt_date, 'dd MMMM yyyy', 'ru-ru') поставка
				from s for json path);
		return @arrivals
	end
go

select inv.arrivals_json(3)

