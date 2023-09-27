IF OBJECT_ID('gendelete', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE gendelete;
END
GO

create procedure gendelete
@tab varchar(128)
AS
BEGIN
    DECLARE @SALIDA TABLE (Texto VARCHAR(2048))
    INSERT INTO @SALIDA VALUES ('IF OBJECT_ID(' + CHAR(39) + 'D_' + @tab + CHAR(39) + ',' + CHAR(39) + 'P' + CHAR(39) + ') IS NOT NULL')
    INSERT INTO @SALIDA VALUES ('    DROP PROCEDURE D_' + @tab)
    INSERT INTO @SALIDA VALUES ('GO')
    INSERT INTO @SALIDA VALUES ('CREATE PROCEDURE D_' + @tab)
    INSERT INTO @SALIDA VALUES ('@ID INTEGER')
    INSERT INTO @SALIDA VALUES ('AS')
    INSERT INTO @SALIDA VALUES ('BEGIN')
    INSERT INTO @SALIDA VALUES ('  BEGIN TRY')
    INSERT INTO @SALIDA VALUES ('    DELETE FROM ' + @tab + ' WHERE ID = @ID')
    INSERT INTO @SALIDA VALUES ('  END TRY')
    INSERT INTO @SALIDA VALUES ('  BEGIN CATCH')
    INSERT INTO @SALIDA VALUES ('     EXECUTE GetErrorInfo_sp')
    INSERT INTO @SALIDA VALUES ('  END CATCH'    )
    INSERT INTO @SALIDA VALUES ('END')
    INSERT INTO @SALIDA VALUES ('GO')
    SELECT Texto FROM @SALIDA
END
GO
IF OBJECT_ID('geninsert', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE geninsert;
END

GO

create procedure geninsert
@tab varchar(128)
AS
BEGIN
    DECLARE @SALIDA TABLE (Texto VARCHAR(2048))
    DECLARE @SQLTEXT VARCHAR(1024)
    DECLARE @VALUES VARCHAR(1024)
    DECLARE @WHERE VARCHAR(1024)
    DECLARE C_COL CURSOR FOR
    select 
        c.COLUMN_NAME, 
        CASE c.DATA_TYPE           
            WHEN 'VARCHAR' then 'VARCHAR(' + RTRIM(LTRIM(STR(c.CHARACTER_MAXIMUM_LENGTH))) + ')'
            WHEN 'CHAR' then 'CHAR(' + RTRIM(LTRIM(STR(c.CHARACTER_MAXIMUM_LENGTH))) + ')'
            ELSE UPPER(c.DATA_TYPE)
        END,
        case 
         when left(k.CONSTRAINT_NAME,3) = 'PK_' then 1 else 0
        end as isPk
    from information_schema.columns c
    left join information_schema.key_column_usage k 
        on k.TABLE_CATALOG  = c.TABLE_CATALOG 
        and k.TABLE_SCHEMA  = c.TABLE_SCHEMA 
        and k.TABLE_NAME = c.TABLE_NAME 
        and k.COLUMN_NAME  = c.COLUMN_NAME 
    where c.TABLE_NAME  = @tab

    DECLARE @COLNAME VARCHAR(128)
    DECLARE @COLTYPE VARCHAR(128)
    DECLARE @ISPK INT
    DECLARE @CNT INTEGER


    INSERT INTO @SALIDA VALUES ('IF OBJECT_ID(' + CHAR(39) + 'I_' + @tab + CHAR(39) + ',' + CHAR(39) + 'P' + CHAR(39) + ') IS NOT NULL')
    INSERT INTO @SALIDA VALUES ('    DROP PROCEDURE I_' + @tab)
    INSERT INTO @SALIDA VALUES ('GO')
    INSERT INTO @SALIDA VALUES ('')
    INSERT INTO @SALIDA VALUES ('CREATE PROCEDURE I_' + @tab)
    OPEN C_COL
    FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    SET @CNT = 0
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN
            IF @ISPK = 1
            BEGIN
                IF @CNT = 0
                    BEGIN
                        INSERT INTO @SALIDA VALUES ('    @' + @COLNAME + ' ' + @COLTYPE + ' OUTPUT' )
                        SET @CNT = 1
                    END
                ELSE
                        INSERT INTO @SALIDA VALUES ('   ,@' + @COLNAME + ' ' + @COLTYPE + ' OUTPUT')
            END
            ELSE
            BEGIN
                IF @CNT = 0
                    BEGIN
                        INSERT INTO @SALIDA VALUES ('    @' + @COLNAME + ' ' + @COLTYPE )
                        SET @CNT = 1
                    END
                ELSE
                        INSERT INTO @SALIDA VALUES ('   ,@' + @COLNAME + ' ' + @COLTYPE )
            END            
        END    
        FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    END
    CLOSE C_COL

    INSERT INTO @SALIDA VALUES ('AS')
    INSERT INTO @SALIDA VALUES ('BEGIN')
    INSERT INTO @SALIDA VALUES ('  BEGIN TRY')
    INSERT INTO @SALIDA VALUES ('    INSERT INTO ' + @tab)
    SET @CNT = 0
    OPEN C_COL
    FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @ISPK = 1
            BEGIN
                SET @WHERE = '    WHERE ' + UPPER(@COLNAME) + ' = @' + @COLNAME
            END
        ELSE
            IF @CNT = 0
                BEGIN
                    SET @SQLTEXT = '    (' + UPPER(@COLNAME)
                    SET @VALUES =  '    (@' + UPPER(@COLNAME)
                    SET @CNT = 1
                END
            ELSE
                BEGIN
                    SET @SQLTEXT = @SQLTEXT + ', ' + UPPER(@COLNAME)
                    SET @VALUES =  @VALUES + ', @' + UPPER(@COLNAME)
                END
        FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    END
    SET @SQLTEXT = @SQLTEXT + ')'
    SET @VALUES = @VALUES + ')'
    INSERT INTO @SALIDA VALUES (@SQLTEXT)
    INSERT INTO @SALIDA VALUES ('    VALUES')
    INSERT INTO @SALIDA VALUES (@VALUES)
    CLOSE C_COL
    DEALLOCATE C_COL
    INSERT INTO @SALIDA VALUES ('')
    INSERT INTO @SALIDA VALUES ('    SET @ID = @@IDENTITY')
    INSERT INTO @SALIDA VALUES ('  END TRY')
    INSERT INTO @SALIDA VALUES ('  BEGIN CATCH')
    INSERT INTO @SALIDA VALUES ('     EXECUTE GetErrorInfo_sp')
    INSERT INTO @SALIDA VALUES ('  END CATCH')
    INSERT INTO @SALIDA VALUES ('END')
    INSERT INTO @SALIDA VALUES ('GO')

    SELECT Texto FROM @SALIDA
END
GO

IF OBJECT_ID('genupdate', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE genupdate;
END
GO
create procedure genupdate
@tab varchar(128)
AS
BEGIN
    DECLARE @SALIDA TABLE (Texto VARCHAR(2048))
    DECLARE @SQLTEXT VARCHAR(1024)
    DECLARE @WHERE VARCHAR(1024)
    DECLARE C_COL CURSOR FOR
    select 
        c.COLUMN_NAME, 
        CASE c.DATA_TYPE           
            WHEN 'VARCHAR' then 'VARCHAR(' + RTRIM(LTRIM(STR(c.CHARACTER_MAXIMUM_LENGTH))) + ')'
            WHEN 'CHAR' then 'CHAR(' + RTRIM(LTRIM(STR(c.CHARACTER_MAXIMUM_LENGTH))) + ')'
            ELSE UPPER(c.DATA_TYPE)
        END,
        case 
            when left(k.CONSTRAINT_NAME,3) = 'PK_' then 1 else 0
        end as isPk
    from information_schema.columns c
    left join information_schema.key_column_usage k 
        on k.TABLE_CATALOG  = c.TABLE_CATALOG 
        and k.TABLE_SCHEMA  = c.TABLE_SCHEMA 
        and k.TABLE_NAME = c.TABLE_NAME 
        and k.COLUMN_NAME  = c.COLUMN_NAME 
    where c.TABLE_NAME  = @tab

    DECLARE @COLNAME VARCHAR(128)
    DECLARE @COLTYPE VARCHAR(128)
    DECLARE @ISPK INT
    DECLARE @CNT INTEGER


    INSERT INTO @SALIDA VALUES ('IF OBJECT_ID(' + CHAR(39) + 'U_' + @tab + CHAR(39) + ',' + CHAR(39) + 'P' + CHAR(39) + ') IS NOT NULL')
    INSERT INTO @SALIDA VALUES ('    DROP PROCEDURE U_' + @tab)
    INSERT INTO @SALIDA VALUES ('GO')
    INSERT INTO @SALIDA VALUES ('')
    INSERT INTO @SALIDA VALUES ('CREATE PROCEDURE U_' + @tab)
    OPEN C_COL
    FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    SET @CNT = 0
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN
            IF @CNT = 0
                BEGIN
                    INSERT INTO @SALIDA VALUES ('    @' + @COLNAME + ' ' + @COLTYPE )
                    SET @CNT = 1
                END
            ELSE
                    INSERT INTO @SALIDA VALUES ('   ,@' + @COLNAME + ' ' + @COLTYPE )
        END    
        FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    END
    CLOSE C_COL

    INSERT INTO @SALIDA VALUES ('AS')
    INSERT INTO @SALIDA VALUES ('BEGIN')
    INSERT INTO @SALIDA VALUES ('  BEGIN TRY')
    INSERT INTO @SALIDA VALUES ('    UPDATE ' + @tab + ' SET')
    SET @CNT = 0
    OPEN C_COL
    FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @ISPK = 1
            BEGIN
                SET @WHERE = '    WHERE ' + UPPER(@COLNAME) + ' = ' + @COLNAME 
            END
        ELSE
            IF @CNT = 0
                BEGIN
                    INSERT INTO @SALIDA VALUES ('        ' + @COLNAME + ' = ISNULL(@' + @COLNAME + ', ' + @COLNAME + ')')
                    SET @CNT = 1
                END
            ELSE
                  INSERT INTO @SALIDA VALUES ('       ,' + @COLNAME + ' = ISNULL(@' + @COLNAME + ', ' + @COLNAME + ')' )

        FETCH C_COL INTO @COLNAME, @COLTYPE, @ISPK
    END
    INSERT INTO @SALIDA VALUES (@WHERE)
    CLOSE C_COL
    DEALLOCATE C_COL
    INSERT INTO @SALIDA VALUES ('  END TRY')
    INSERT INTO @SALIDA VALUES ('  BEGIN CATCH')
    INSERT INTO @SALIDA VALUES ('     EXECUTE GetErrorInfo_sp')
    INSERT INTO @SALIDA VALUES ('  END CATCH')
    INSERT INTO @SALIDA VALUES ('END')
    INSERT INTO @SALIDA VALUES ('GO')
    SELECT Texto FROM @SALIDA
END
GO


IF OBJECT_ID('GetErrorInfo_sp', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE GetErrorInfo_sp;
END
GO

CREATE PROCEDURE GetErrorInfo_sp  
AS  
SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
GO  
