if OBJECT_ID('inv.newPackageTransaction_') is not null drop proc inv.newPackageTransaction_
go 
create proc inv.newPackageTransaction_ @userName varchar (255)
as
set nocount on;
	insert inv.transactions (userID, transactiontypeID)
	select  org.person_id(@userName), inv.transactiontype_id('STORAGE')
	select SCOPE_IDENTITY()

go






--set nocount on; exec inv.newPackageTransaction_ @userName = '¡¿À”ÿ »Õ¿ ¿. ¿.'
select * from inv.transactions t order by 1 desc