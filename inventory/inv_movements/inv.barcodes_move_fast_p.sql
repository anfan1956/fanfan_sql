USE [fanfan]
GO
/*
*****         	Object:  StoredProcedure [inv].[barcodes_move_fast_p]   Script Date: 21.03.2025 18:39:34 
*****			Added boxes in storage									Script Date: 21.03.2025 19:09
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc inv.barcodes_move_fast_p 
    @info dbo.id_type readonly,  
    @date date, 
    @division varchar (max),
    @userid int,
    @note varchar (max) output
as 

set nocount on;
declare @message varchar (max)= 'Just debugging', @comment varchar(max)='fast track';
declare @divisionid int = org.division_id(@division)
declare @transactiontypeid int = inv.transactiontype_id('MOVEMENT');
declare @carrierid int = (select clientID from org.divisions d where d.divisionfullname=@division);
declare @targetid int = @carrierid;

declare @transactions table (transactionid int);
declare @waybills table (transactionid int, warehouseid int);
declare @inventory table (clientid int, logstateid int, divisionid int, transactionid int, opersign int, barcodeid int)
declare @divisions table (divisionid int, num int, transactionid int);


begin try
    begin transaction;

--waybill out 
--define number of     transaction by defining the number of divisions in the take and creating table 
        with s (divisionid) as 
            (select distinct r.divisionID
                from @info i 
                    join inv.v_remains r on r.barcodeID=i.Id
                where r.divisionID<>@divisionid )
        insert @divisions (divisionid, num) select divisionid, ROW_NUMBER() over (order by divisionid) from s;

        insert inv.transactions(transactiondate, transactiontypeID, userID)
        output inserted.transactionid into @transactions
        select @date, @transactiontypeid , @userid
        from @divisions;

        with s (transactionid, num) as (select t.transactionid, ROW_NUMBER () over (order by transactionid) 
        from @transactions t)
            update @divisions set transactionid=s.transactionid
            from s join @divisions d on d.num=s.num;

        with s  (clientid, logstateid, divisionid, transactionid, barcodeid) as 
        (
            select v.clientID, v.logstateID, d.divisionid, d.transactionid, i.id 
            from @info i
                join inv.v_remains v on i.Id=v.barcodeID
                join @divisions d on d.divisionid=v.divisionID            
        )
        , _sign (opersing) as (select -1 union all select 1) 
            insert inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
            output inserted.* into @inventory
            select s.clientID, s.logstateID, 
                case si.opersing when -1 then s.divisionid else 0 end divisionid,s.transactionid, si.opersing, s.barcodeid
            from s
                cross apply _sign si ;

            insert inv.waybills (waybillID, targetID, targetwarehouseID, warehouseID, personID, carrierID, comment)
            select transactionid, @targetid, @divisionid, d.divisionid, @userid, @carrierid, @comment
            from @divisions d;
    

----_______________now waybill in
        delete @transactions;

        insert inv.transactions(transactiondate, transactiontypeID, userID)
        output inserted.transactionid into @transactions
        select @date, @transactiontypeid , @userid
        from @divisions;

        with s (transactionid, num) as (select t.transactionid, ROW_NUMBER () over (order by transactionid) 
        from @transactions t)
            update @divisions set transactionid=s.transactionid
            from s join @divisions d on d.num=s.num;

        with s  (clientid, logstateid, divisionid, transactionid, barcodeid) as 
        (
            select v.clientID, v.logstateID, v.divisionid, d.transactionid, i.id 
            from @info i
                join @inventory v on i.Id=v.barcodeID and v.opersign=-1                
                join @divisions d on d.divisionid=v.divisionID            
        )
        , _sign (opersing) as (select -1 union all select 1) 
            insert inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
            select s.clientID, s.logstateID, 
                case si.opersing when -1 then 0 else @divisionid end divisionid, 
                s.transactionid, si.opersing, s.barcodeid
            from s
                cross apply _sign si ;

            insert inv.waybills (waybillID, targetwarehouseID, warehouseID, personID, carrierID, comment)
            select transactionid, null, @divisionid, @userid, @carrierid, @comment
            from @divisions d  
            declare @n varchar (max) = cast(@@rowcount as varchar(max))

			--check the boxes
			;with _bcodes (barcodeid, boxid) as (
			select s.barcodeid, s.boxid 
			from inv.storage_box s
				join @info i on i.Id=s.barcodeid

			group by s.barcodeID, s.boxid
			having sum(s.opersign)>0
			)
			insert inv.storage_box(boxID, barcodeID, opersign)
			select 
				boxid, barcodeid, -1 
			from _bcodes;
			
            select @note =  @n + 'шт. - расходных и ' + @n + 'шт. - приходных накладных. Следует провести в 1С'

    --;throw 50001, @message, 1
    commit transaction
end try
begin catch
    set @note = ERROR_MESSAGE()
    rollback transaction
end catch
go 


set nocount on; declare @note varchar(max), @info dbo.id_type; 
insert @info values (653588), (657605); 
declare @date date= '20250321' , @division varchar (max) = '07 УИКЕНД', @userid int = 1; 
--exec inv.barcodes_move_fast_p @info, @date, @division, @userid,  @note output; select @note;