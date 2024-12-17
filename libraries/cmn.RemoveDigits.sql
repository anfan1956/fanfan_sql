if OBJECT_ID ('cmn.RemoveDigits') is not null drop function cmn.RemoveDigits
go
CREATE FUNCTION cmn.RemoveDigits (@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    WHILE PATINDEX('%[0-9]%', @input) > 0
        SET @input = STUFF(@input, PATINDEX('%[0-9]%', @input), 1, '');
    RETURN @input;
END;
GO