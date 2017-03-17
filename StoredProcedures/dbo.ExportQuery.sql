USE [master]
GO
IF OBJECT_ID('dbo.ExportQuery') IS NOT NULL DROP PROCEDURE dbo.ExportQuery
GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ExportQuery
	@FileName	nvarchar(max),
	@Query		nvarchar(max),
	@ExpHeaders smallint,
	@ExpLFOnly	smallint,
	@NoTrim		smallint,
	@Separator	nvarchar(max),
	@Decode		smallint
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME ExportFunctions.ExportFunctions.ExportQuery
GO