

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_column_unique' AND object_id = OBJECT_ID('inv.barcodes'))
BEGIN
    DROP INDEX idx_column_unique ON inv.barcodes;
END

alter table inv.barcodes
alter column mark_code varchar(83) 
select * from inv.barcodes

CREATE UNIQUE NONCLUSTERED INDEX idx_column_unique
ON inv.barcodes (mark_code)
WHERE mark_code IS NOT NULL;

