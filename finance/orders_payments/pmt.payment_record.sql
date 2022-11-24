use fanfan
go

--- если база рабочая, СКРИПТ НЕ ЗАПУСКАТЬ!

if OBJECT_ID ('pmt.payment_record_p') is not null drop proc pmt.payment_record_p
go
create proc  pmt.payment_record_p
				@note varchar(max) output,
				@pmtdate date, 
				@id int, 
				@pmt_type varchar(25), 
				@bank varchar(50), 
				@bank_card varchar(20), 
				@cur_code char(3), 
				@card_amount money, 
				@order_amount money, 
				@employee varchar(37), 
				@cargo varchar(50)
	
as
begin
set nocount on;
	begin try
		begin transaction
			declare 
				@paymentid int, 
-- это только для Fashion Distribution.
-- возможно придется переписать процедуру, если появятся другие
				@importer_commission decimal (4,3) = .03,
				@bank_commission decimal(4,3) = .025;

			with _s (pmtdate, vendorid, registerid, amount, importerid, employeeid) as (
				select @pmtdate, c.contractorid, r.registerid, @card_amount, c2.contractorID, p.personID
				from org.contractors c
					join inv.orders o on o.vendorID=c.contractorID and o.orderID= @id					
					join org.contractors c2 on c2.contractor=@cargo
					cross apply pmt.registers r
					cross apply org.persons p
				where r.bankcard = @bank_card and p.lfmname = @employee
			)
			insert pmt.orderspayments (pmtdate, vendorid, registerid, amount, importerid, employeeid)
			select pmtdate, vendorid, registerid, amount, importerid, employeeid from _s;
			set @paymentid = SCOPE_IDENTITY();
--				select * from pmt.orderspayments;

			with _s (paymentid, orderid, typeid, amount, importer_commission, bank_commission) as (
				select @paymentid, @id, pt.typeid, @order_amount, 
					@importer_commission, @bank_commission
				from pmt.orderspayment_types pt
				where pt.type= @pmt_type
			)
			insert pmt.payment_orders (paymentid, orderid, typeid, amount, importer_commission, bank_commission)
			select paymentid, orderid, typeid, amount, importer_commission, bank_commission from _s;
--			select * from pmt.payment_orders;
			select @note = 'записан платеж №' + cast(@paymentid as varchar(max)) + ': ' + @pmt_type + ' - на сумму ' + cast(@card_amount as varchar(max)) 
			 + ' ' + @cur_code + ' к заказу ' + cast (@id as varchar(max));
--			throw 50001, 'just debuggin', 1;
			commit transaction;
		end try
	begin catch
		select @note = ERROR_MESSAGE();
		rollback transaction
	end catch
end 
go

declare @note varchar(max);
--exec pmt.payment_record_p @note output, '20221111', 75380., 'deposit', 'СБЕРБАНК', '2202200417309265', 'RUR', 87000., 1279.25, 'ПИКУЛЕВА О. Н.', 'FASHION DISTRIBUTION SRL'
--select @note;
select * from pmt.orderspayments
select * from pmt.payment_orders

if OBJECT_ID('pmt.payment_orders') is not null drop table pmt.payment_orders
if OBJECT_ID('pmt.orderspayments') is not null drop table pmt.orderspayments

create table pmt.orderspayments (
	paymentid int not null identity constraint pk_orders_pmts primary key, 
	pmtdate date not null, 
	vendorid int not null constraint fk_orders_payments foreign key references org.vendors (vendorid),
	registerid int not null constraint fk_orderspayments_registers references pmt.registers (registerid),
	amount money not null, 
	importerid int null constraint fk_pmt_opders_cargo foreign key references org.cargo (cargoid),
	employeeid int not null constraint fk_orders_pmt_emp foreign key references org.persons (personid), 
	time_stamp datetime default current_timestamp 
)
create table pmt.payment_orders (
	paymentid int not null constraint fk_pmt_pmt_orders foreign key references pmt.orderspayments (paymentid),
	orderid int not null constraint  fk_pmt_orders foreign key references inv.orders (orderid),
	typeid int not null  constraint  fk_pmt_pmttypes foreign key references pmt.orderspayment_types (typeid),
	amount money not null, 
	importer_commission decimal (4,3) null, 
	bank_commission decimal (4,3) null 
)