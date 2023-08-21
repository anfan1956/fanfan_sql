--===== Create and populate a test table.
     -- This is NOT a part of the solution.
DECLARE @Demo TABLE(OriginalString VARCHAR(8000))
 INSERT INTO @Demo (OriginalString)
 SELECT '  This      has multiple   unknown                 spaces in        it.   ' UNION ALL
 SELECT 'So                     does                      this!' UNION ALL
 SELECT 'As                                does                        this' UNION ALL
 SELECT 'This, that, and the other  thing.' UNION ALL
 SELECT 'This needs no repair.'
--===== Reduce each group of multiple spaces to a single space
     -- for a whole table without functions, loops, or other
     -- forms of slow RBAR.  In the following example, CHAR(7)
     -- is the "unlikely" character that "X" was used for in 
     -- the explanation.
SELECT REPLACE(
            REPLACE(
                REPLACE(
                    LTRIM(RTRIM(OriginalString))
                ,'  ',' '+CHAR(127))  --Changes 2 spaces to the OX model
            ,CHAR(127)+' ','')        --Changes the XO model to nothing
        ,CHAR(127),'') AS CleanString --Changes the remaining X's to nothing
   FROM @Demo
  WHERE CHARINDEX('  ',OriginalString) > 0

if OBJECT_ID('cmn.norm_') is not null drop function cmn.norm_
go
create function cmn.norm_(@str varchar(max)) returns varchar(max)
as 
	begin
		declare @norm_ed varchar(max);

		SELECT @norm_ed =  REPLACE(
					REPLACE(
						REPLACE(
							LTRIM(RTRIM(@str))
						,'  ',' '+CHAR(127))  --Changes 2 spaces to the OX model
					,CHAR(127)+' ','')        --Changes the XO model to nothing
				, CHAR(127),'') -- AS CleanString --Changes the remaining X's to nothing
		--WHERE CHARINDEX('  ', @str) > 0

	  return @norm_ed
	end
go
declare @color varchar(max), @color2 varchar(max);
select @color = ' some              very  new color      ok   '
select @color2 = cmn.norm_(@color)
  select @color2, len(@color2);

declare @bcolor varchar(max) =  (select top 1 color from web.basketLogs)
select @bcolor = '   34300    BLACK';
select cmn.norm_(@bcolor), len(@bcolor), len(cmn.norm_(@bcolor))
--from web.basketLogs bl