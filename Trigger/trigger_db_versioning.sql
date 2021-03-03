USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
--/----------------------------------------------------------------------------------------------
-- THIS TRIGGER CAN KEEP TRACK OF YOUR CHANGES YOU MAKE TO SQL SERVER
-- LIKE NEW PROCEDURES, FUNCTIONS OR CHANGES TO THEM.
-- IT WILL WRITE OUT AN FILE (SQL SCRIPT) THAT YOU CAN PUT INTO VERSION CONTROL LIKE GIT
--/----------------------------------------------------------------------------------------------
CREATE TRIGGER [TRIGGER_DB_VERSIONING] ON ALL SERVER

FOR
	CREATE_TABLE, DROP_TABLE, ALTER_TABLE,
	CREATE_PROCEDURE, DROP_PROCEDURE,ALTER_PROCEDURE,
	CREATE_VIEW, DROP_VIEW, ALTER_VIEW,
	CREATE_TRIGGER, ALTER_TRIGGER, DROP_TRIGGER,
	CREATE_FUNCTION, ALTER_FUNCTION,DROP_FUNCTION,
	CREATE_INDEX, ALTER_INDEX,DROP_INDEX,
	
	-- SERVICE BROKER
	CREATE_CONTRACT, DROP_CONTRACT,
	CREATE_SERVICE, ALTER_SERVICE,DROP_SERVICE,
	CREATE_QUEUE, ALTER_QUEUE, DROP_QUEUE,
	CREATE_MESSAGE_TYPE, ALTER_MESSAGE_TYPE, DROP_MESSAGE_TYPE,

	-- SECURITY
	CREATE_SCHEMA, ALTER_SCHEMA, DROP_SCHEMA,
	CREATE_USER, ALTER_USER, DROP_USER

AS

SET NOCOUNT ON
SET XACT_ABORT OFF;

BEGIN TRY
	
	DECLARE @DATA XML = EVENTDATA()
	DECLARE @SERVER		VARCHAR(100) = @DATA.value('(/EVENT_INSTANCE/ServerName)[1]','VARCHAR(100)')
	DECLARE @DATABASE	VARCHAR(100) = @DATA.value('(/EVENT_INSTANCE/DatabaseName)[1]','VARCHAR(100)')
	DECLARE @USER		VARCHAR(100) = @DATA.value('(/EVENT_INSTANCE/LoginName)[1]','VARCHAR(100)')
	DECLARE @SCHEMA		VARCHAR(100) = @DATA.value('(/EVENT_INSTANCE/SchemaName)[1]','VARCHAR(100)')
	DECLARE @OBJECT		VARCHAR(100) = @DATA.value('(/EVENT_INSTANCE/ObjectName)[1]','VARCHAR(100)')
	DECLARE @ACTION		VARCHAR(100) = @DATA.value('(/EVENT_INSTANCE/EventType)[1]','VARCHAR(100)')
	DECLARE @CODE		VARCHAR(MAX) = @DATA.value('(/EVENT_INSTANCE/TSQLCommand)[1]','VARCHAR(MAX)')
	
	--/----------------------------------------------------------------------------------------------
	-- SET THE BASEPATH FOR THE FOLDERS AND FILES
	-- FOLDER\DATABASE\
	-- FOLDER PATH IS RELATIVE TO YOUR SERVER, WHERE THE SQL SERVER LIVES
	--/----------------------------------------------------------------------------------------------
	DECLARE @FOLDERPATH VARCHAR(255)
	SET @FOLDERPATH = 'C:\CodeBase\database-development\'

	--/----------------------------------------------------------------------------------------------
	-- SKIP LOCK ESCALATION STATEMENTS
	--/----------------------------------------------------------------------------------------------
	IF @CODE NOT LIKE '%LOCK_ESCALATION%'
	BEGIN
		
		IF OBJECT_ID('tempdb..#CODE') IS NOT NULL DROP TABLE #CODE;
		CREATE TABLE #CODE (
			[CODE] VARCHAR(MAX)
		)

		-- IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sms_tarief]') AND type in (N'U'))
		DECLARE @EXTRA_CODE		VARCHAR(MAX) = ''
		
		--/----------------------------------------------------------------------------------------------
		-- PROCEDURE DROP/CREATE
		--/----------------------------------------------------------------------------------------------
		IF     @ACTION = 'CREATE_PROCEDURE' OR @ACTION = 'ALTER_PROCEDURE'
			OR @ACTION = 'CREATE_FUNCTION'	OR @ACTION = 'ALTER_FUNCTION'
			OR @ACTION = 'CREATE_TRIGGER'	OR @ACTION = 'ALTER_TRIGGER'
			OR @ACTION = 'CREATE_VIEW'		OR @ACTION = 'CREATE_VIEW'
		BEGIN
			
			DECLARE @TYPE	VARCHAR(20)
			
			SET @TYPE = RTRIM(SUBSTRING(@ACTION, CHARINDEX('_', @ACTION) + 1, 9))

			SET @EXTRA_CODE = 'IF OBJECT_ID(''' + @SCHEMA + '.' +@OBJECT  +''') IS NOT NULL DROP ' + @TYPE + ' ' + @SCHEMA + '.' +@OBJECT  + ';' + CHAR(10)
			SET @EXTRA_CODE = @EXTRA_CODE + 'GO ' + CHAR(10)
			
			IF @ACTION = 'ALTER_PROCEDURE'
			BEGIN
				SET @CODE = REPLACE(@CODE, 'ALTER PROCEDURE', 'CREATE PROCEDURE')
			END
			IF @ACTION = 'ALTER_FUNCTION'
			BEGIN
				SET @CODE = REPLACE(@CODE, 'ALTER FUNCTION', 'CREATE FUNCTION')
			END
			IF @ACTION = 'ALTER_TRIGGER'
			BEGIN
				SET @CODE = REPLACE(@CODE, 'ALTER TRIGGER', 'CREATE TRIGGER')
			END
			IF @ACTION = 'ALTER_VIEW'
			BEGIN
				SET @CODE = REPLACE(@CODE, 'ALTER VIEW', 'CREATE VIEW')
			END
		END

		IF @ACTION = 'CREATE_INDEX'
		BEGIN
			
			DECLARE @TABLENAME	VARCHAR(50)
			,		@QUERY		VARCHAR(MAX)

			SET @QUERY = '
			SELECT	O.name 
			FROM	'  + @DATABASE + '.sys.indexes	S
			JOIN	'  + @DATABASE + '.SYS.objects O ON S.object_id = O.object_id
			WHERE	S.name='''+ @OBJECT  +'''
			';
			
			DECLARE @T TABLE(RESULT VARCHAR(150))
			INSERT INTO @T
			EXEC (@QUERY);

			SELECT @TABLENAME = result FROM @T

			SET @EXTRA_CODE = 
			'IF EXISTS (
				SELECT	* 
				FROM	sys.indexes		I
				JOIN	sys.tables		T ON I.object_id = T.object_id
				JOIN	sys.schemas		S ON S.schema_id = T.schema_id
			   WHERE	I.Name = '''+ @OBJECT  +''' 
				 AND	T.Name = '''+ @TABLENAME  +''' 
				 AND	S.Name = '''+ @SCHEMA +''') 
			BEGIN
				DROP INDEX ['+ @OBJECT  +'] ON ['+ @SCHEMA  +'].['+ @TABLENAME  +']
			END;'
			SET @EXTRA_CODE = @EXTRA_CODE + CHAR(10)
			SET @EXTRA_CODE = @EXTRA_CODE + 'GO ' + CHAR(10)
		END

		

		--/----------------------------------------------------------------------------------------------
		-- EXTEND THE CODE TO BE WRITTEN TO FILE TO CONTAIN EXTRA INFORMATION
		--/----------------------------------------------------------------------------------------------
		DECLARE @META_CODE		NVARCHAR(500)
		,		@COMPLETE_CODE	NVARCHAR(MAX)
		,		@ENDOF			NVARCHAR(500)

		SET @META_CODE = 'USE ' + @DATABASE  + CHAR(10)
		SET @META_CODE = @META_CODE + 'GO' + CHAR(10)
		SET @META_CODE = @META_CODE + 'SET ANSI_NULLS ON' + CHAR(10)
		SET @META_CODE = @META_CODE + 'GO' + CHAR(10)
		SET @META_CODE = @META_CODE + 'SET QUOTED_IDENTIFIER ON' + CHAR(10)
		SET @META_CODE = @META_CODE + 'GO' + CHAR(10)
		SET @META_CODE = @META_CODE + CHAR(10)
		SET @META_CODE = @META_CODE + '--/--------------------------------------------------------------------------------------------' + CHAR(10)
		SET @META_CODE = @META_CODE + '-- SCRIPT CREATED BY TRIGGER INITIATED BY ' + @USER + ' @ ' + CONVERT(VARCHAR(19),GETDATE(),121) + CHAR(10)
		SET @META_CODE = @META_CODE + '--/--------------------------------------------------------------------------------------------' + CHAR(10)
		SET @META_CODE = @META_CODE + CHAR(10)

		SET @ENDOF	   = CHAR(10)

		SET @COMPLETE_CODE = @META_CODE + @EXTRA_CODE + @CODE + @ENDOF
		
		INSERT INTO #CODE ( [CODE] )
		SELECT @COMPLETE_CODE;

		--/----------------------------------------------------------------------------------------------
		-- WRITE TO DATABASE TABLE IF YOU WANT TO KEEP TRACK OF VERSIONS
		-- CREATE TABLE AND ADJUST
		--/----------------------------------------------------------------------------------------------
		--IF OBJECT_ID('dbo.VERSIONING') IS NOT NULL
		--BEGIN
		--	INSERT INTO dbo.VERSIONING ([SERVER],[DATABASE],[USER],[SCHEMA],[OBJECT],[ACTION],[DATE],[CODE])
		--	VALUES (@SERVER,@DATABASE,@USER,@SCHEMA, @OBJECT,@ACTION,GETDATE(),ISNULL(@COMPLETE_CODE,'NA'))
		--END

		--/----------------------------------------------------------------------------------------------
		-- DETERMINE DESTINATION FOLDER BY ACTION
		--/----------------------------------------------------------------------------------------------
		DECLARE @FOLDER VARCHAR(100)
		SELECT @FOLDER = CASE 
							WHEN @ACTION LIKE '%FUNCTION'	 THEN '\UserDefinedFunctions'
							WHEN @ACTION LIKE '%PROCEDURE'	 THEN '\StoredProcedures'
							WHEN @ACTION =	  'CREATE_TABLE' THEN '\Tables'
							WHEN @ACTION =	  'ALTER_TABLE'	 THEN '\Tables\Alter'
							WHEN @ACTION =	  'DROP_TABLE'	 THEN '\Tables\Drop'
							WHEN @ACTION LIKE '%VIEW'		 THEN '\Views'
							WHEN @ACTION LIKE '%INDEX'		 THEN '\Tables\Indexes'
							WHEN @ACTION LIKE '%TRIGGER'	 THEN '\Triggers'
							WHEN @ACTION LIKE '%SCHEMA'		 THEN '\Schemas'
							WHEN @ACTION LIKE '%USER'		 THEN '\Users'
						 END


		DECLARE @CHECKDIR NVARCHAR(100)
		SET @CHECKDIR = @FOLDERPATH + @DATABASE 
	
		CREATE TABLE #ResultSet (Directory varchar(200))

		INSERT INTO #ResultSet
		EXEC master.dbo.xp_subdirs @CHECKDIR

		-- CREATE FOLDER IF NOT EXISTS
		IF ( SELECT COUNT(*) FROM #ResultSet WHERE Directory = @FOLDER ) = 0 OR ( SELECT COUNT(*) FROM #ResultSet where Directory = @DATABASE ) = 0
		BEGIN
	  
		  DECLARE @FILEPATH NVARCHAR(500)
		
		  SET @FILEPATH = '' + @CHECKDIR + '\' + @FOLDER;
		  EXEC master.sys.xp_create_subdir @FILEPATH

		END
	
		DROP TABLE #ResultSet;			
	
		DECLARE @fileName NVARCHAR(250)
		
		SET @fileName = @SCHEMA + '.' + @OBJECT
		
		-- CREATE SQL FILE FOR GIT
		DECLARE @Path	NVARCHAR(100)	= @FOLDERPATH + @DATABASE + @FOLDER
		DECLARE @fName  NVARCHAR(500)
		DECLARE @sql    VARCHAR(MAX)	= 'SELECT CODE FROM #CODE'
		SET @fName = @Path + '\' + @fileName + '.sql'
		
		-- USE EXPORT FUNCTION
		EXEC [master].dbo.ExportQuery @fName, @sql, 0, 0, 1, '', 0;
		
		DROP TABLE #CODE;
	
	END

END TRY 
BEGIN CATCH 
	--/------------------------------------------------------------------------------
	-- ERROR HANDLING
	--/------------------------------------------------------------------------------
	SELECT 'error', @@ERROR

END CATCH

RETURN


GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

ENABLE TRIGGER [TRIGGER_DB_VERSIONING] ON ALL SERVER
GO


