declare @customerid int = 17427;
declare @phone varchar(12) = '9167834248'
select * from cust.connect where connect like '%91678342%'
if exists(select * from sms.phones p where right(p.phone, 10) = @phone) 
	select 'этот телефон уже есть в базе'
else 
	select 'этого телефона нет в базе'
--p.phone like '%' + @phone + '%'

--exec cust.person_delete @customerid



declare @r int, @note varchar (max);
--exec @r = cust.cust_registration_tsheets_p 'ФЕДОРОВ А. Н.', 'FANFAN.STORE', 'fan', 'fan', 'Fanfan', 'Муж', '', '79167834248', '', @note OUTPUT; select @note;
--exec @r = cust.cust_registration_tsheets_p 'ФЕДОРОВ А. Н.', 'FANFAN.STORE', 'Федоров', 'Александр', '', 'Муж', '', '79167834248', '', @note OUTPUT; select @note
 select * from sms.phones p where p.customerid = @customerid
 select * from cust.connect c where c.personID = @customerid
 go
declare @r int, @note varchar(max); 
---exec @r = cust.cust_registration_tsheets_p 'ФЕДОРОВ А. Н.', 'FANFAN.STORE', 'Федоров', 'Александр', '', 'муж', '', '9167834248', 'af.fanfan.2012@gmail.com', @note OUTPUT; 
select @note, @r
 select * from cust.persons order by 1 desc