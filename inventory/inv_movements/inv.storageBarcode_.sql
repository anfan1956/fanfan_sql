if OBJECT_ID('inv.storageBarcode_') is not null drop proc inv.storageBarcode_
go
create proc inv.storageBarcode_ @bcID int , @BoxID int, @WH varchar(255), @userName varchar(255)
as
	begin try
		begin transaction
			declare @opersing int, @transID int;
			declare @info table (barcodeid int);
			insert @info select @bcID;

			-- ��������, ��������� �� ������ ������ �� ������. 
			-- ���� ���, �� ������������ ���������� �� ����������� ������ �� �����
			if org.division_id(@WH)<> (
						select top 1 i.divisionID
						from inv.inventory i 
						where 1=1
							and i.barcodeID = @bcID
							and i.opersign  = 1
						order by i.transactionID desc
						)
			begin	
				insert inv.transactions(transactiontypeID, userID)
				select inv.transactiontype_id('STORAGE'), org.person_id(@userName)
				select @transID = SCOPE_IDENTITY();				

				-- ���� ����� �� ��������� �� ������ ������, ���������� ����� ������, ��� �� ��� �� ������ �����
				with seed (clientid, logstateID, divisionID, transactionid, opersign, barcodeid) as (
				select iv.clientID, iv.logstateID, iv.divisionID, iv.transactionID, iv.opersign, iv.barcodeID
				from @info inf
					outer apply (select top 1  
						clientID, logstateID, divisionID, @transID transactionID, -1 opersign, i.barcodeID					
						from inventory i
						where 1=1 
							and i.barcodeID = inf.barcodeID	
							and i.opersign > 0
						order by i.transactionID desc
					) as iv
				union all
				select 
					org.client_id_clientRUS ('�� �������')
					, inv.logstate_id('IN-WAREHOUSE')
					, org.division_id(@WH)
					, @transID
					, 1
					, i.barcodeID
					from @info i			
				)
				insert inv.inventory (clientID, logstateID, divisionID, transactionID, opersign, barcodeID)
				select clientID, logstateID, divisionID, transactionID, opersign, barcodeID from seed;
			END		

			-- ������� ����� �� ��� ������� ��� �� ���, ����� ��� � ������� ������ ������
			;with  _otherBoxes as (
			select sum(opersign) qty, boxID
			from inv.storage_box sb
			where 1=1 
				and sb.boxID not in (@BoxID)
				and sb.barcodeID = @bcID
			group by boxID
			having sum(opersign)>0
			)
			insert inv.storage_box(boxID, barcodeID, opersign)
			select ob.boxID, @bcID, -1
			from _otherBoxes ob;

			--���� ����� ��� ��� � �������, ������� ��� ������, �� �� ������� �� ������ ��������
			--���� �� ����� ������ � ������� ����� ����� ������� ��� � �������� 
			--���� ��� ������ ����� ���������� � ������ �������, ����� �� ������� ��� �� ���� ��������� ���������
			;if (
				select 
					coalesce(sum(opersign), 0)
				from inv.storage_box sb
				where 
					sb.boxID = @BoxID
					and sb.barcodeID =@bcID
				) = 0
			select @opersing = 1;
			else 
			select @opersing = -1

			insert inv.storage_box (boxID, barcodeID, opersign)
			select @BoxID, @bcID, @opersing
		commit transaction
	end try
	begin catch
		select ERROR_MESSAGE()
		rollback transaction
	end catch
go

declare @bcID int = 582713, @boxID int  = 1,  @WH varchar(255) = 'BunkovoStorage', @userName varchar(255) = '��������� �. �.'; 
-- 
--exec inv.storageBarcode_ @bcID, @boxID, @WH, @userName; 
select * from inv.storage_box 
