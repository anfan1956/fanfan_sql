﻿declare @months int = 3, @json varchar(max); 


if OBJECT_ID('inv.arrivals_json') is not null drop function inv.arrivals_json
go

create function inv.arrivals_json(@months as int = 3, @sortfield as varchar(25) = 'дата', @sortdesc as bit = 'True') returns varchar(max) as
	begin
		declare @arrivals varchar(max);
		declare @n int = @months;
		if @months=0
		begin
			select @n= max(DATEDIFF(m, s.receipt_date, getdate()))
			from inv.styles_catalog_v s; 
		end ;


			with s as (
				select iif(gender = '', 'УНИ', gender) gender, brand, category, article, styleid, photo_filename, receipt_date, price, discount
				from inv.styles_catalog_v where receipt_date >= DATEADD(mm, -@n, CURRENT_TIMESTAMP)
			)
			select @arrivals = 
				(select 
					format(receipt_date, 'dd MMMM yyyy', 'ru-ru') дата,
					s.brand бренд, 
					s.styleid модель, 
					s.article артикул,
					s.category категория, 
					format(s.price, '#,##0.00 руб.') цена , 
					s.discount скидка, 
					s.photo_filename фото

				from s order by 
					--s.receipt_date asc
					case when @sortfield = 'дата' and @sortdesc = 'True' then s.receipt_date end desc,
					case when @sortfield = 'дата' and @sortdesc = 'False' then s.receipt_date end asc,
					case when @sortfield = 'модель' and @sortdesc = 'True' then s.styleid end desc,
					case when @sortfield = 'модель' and @sortdesc = 'False' then s.styleid end asc,
					case when @sortfield = 'бренд' and @sortdesc = 'True' then s.brand end desc,
					case when @sortfield = 'бренд' and @sortdesc = 'False' then s.brand end asc,
					case when @sortfield = 'цена' and @sortdesc = 'True' then s.price end desc,
					case when @sortfield = 'цена' and @sortdesc = 'False' then s.price end asc,
					case when @sortfield = 'скидка' and @sortdesc = 'True' then s.discount end desc,
					case when @sortfield = 'скидка' and @sortdesc = 'False' then s.discount end asc
				for json path );
		return @arrivals
	end
go

select inv.arrivals_json(default, default, default)
