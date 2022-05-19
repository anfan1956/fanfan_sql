use fanfan
go
/*
На странице товара ( я так понимаю, когда страница обновляется, а также, когда обновляется страница корзины)
выполняется запрос : (пример со стилем 19321)
*/
declare @styleid int = 19321 ;
select color, size, sizeid, qty, price 
from inv.style_colors_sizes_avail (@styleid) ORDER BY color ASC, sizeid
use fanfan
