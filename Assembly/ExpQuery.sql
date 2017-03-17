Use master
GO

ALTER DATABASE master SET TRUSTWORTHY ON;

CREATE ASSEMBLY ExportFunctions
FROM 'C:\Temp\sql\Assemblies\ExpQuery.dll' -- Adjust to your location
WITH PERMISSION_SET = EXTERNAL_ACCESS;

GO