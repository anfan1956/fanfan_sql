/*
На странице товара ( я так понимаю, когда страница обновляется)
выполняется запрос :
*/
declare @styleid int = 19321 ;
select color, size, sizeid, qty from inv.style_colors_sizes_avail (@styleid) ORDER BY color ASC, sizeid