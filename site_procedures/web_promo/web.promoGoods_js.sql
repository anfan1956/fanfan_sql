if OBJECT_ID('web.promoGoods_js') is not null drop function web.promoGoods_js
go
create function web.promoGoods_js () returns varchar(max) as 
	begin
		declare @goods varchar(max);
		with s (бренд, категория, модель, промо, скидка, цена, артикул, num, фото) as (
		select 
			sc.brand, sc.category,
			sd.styleid, sd.discount, p.discount, w.price, 
			sc.article, 
			ROW_NUMBER() over(partition by p.styleid order by p.pricesetid desc), 
			sc.photo_filename
		from web.promo_events e 
			join web.promo_styles_discounts sd on sd.eventid=e.eventid
			join inv.prices p on p.styleID= sd.styleid
			join web.stylesPrices_discounts_v w on w.styleID=sd.styleid
			join inv.styles_catalog_v sc on sc.styleid=sd.styleid

		where	
			cast(getdate() as date) between e.datestart and e.datefinish 
			and eventClosed = 'False'
			)
		select @goods = (select бренд, категория, модель, артикул, промо, скидка, цена, фото
		from s 
		where num =1
		for json path)
		return @goods;
	end
go
select web.promoGoods_js ();


* 

from inv.prices
