# ssmsGit
SQL Server Management Studio Source Control with Git, the DevOps approach.

## Synopsis
This project is an collection of software and t-sql code in order to get your SQL Server under version control without the need to install expensive tools like RedGate's solution for source control. All the code and assemblies are free to use.
I thought it would be nice to share this maybe getting some feedback, tips or people would get inspired to setup an similar environment.

It will take some time and skill to get it running but I will try to be as detailed as possible. The setup has some requirements to get it to work but if you are as resourcefull as me you can adjust it so it works for your environment.

## Requirements
These requirements are based on my setup. 
- SQL Server 2008R2/2012/2016
- Management Studio
- Gitlab ( not required, but you will need central git repository somewhere )
- Git for windows ( not required )
- SourceTree
- SQL Server Trigger
- Export assembly
- Local Development server like SQL Express
- Staging/Build server
- Jenkins
- SQL Package

## Global workflow
Edit procedures, views, tables and saving them to SQL Server directly will trigger an event. The SQL Code is exported to an local git repository that is cloned from an remote. I use gitlab to manage the projects. Once you are finished developing commit the changes and push to the remote branch. Jenkins will build the release and apply the SQL code to the staging database. SQL Package will run against the latest build database and create and change script that can be applied to an build database. Some testing needs to be done and the change script can be applied to the production environment. This is how you would achieve continues integration for SQL Server.

## ExportQuery
I have been using this stored procedure for a while now. You can export an table directly from your script to an txt or csv file with our without headers and using an fieldterminator like ',' or ';'

The assembly is required for the exportquery to run and you will have to set the trustworthy setting on your database on.

### Setup ExportQuery
download the assembly ExpQuery to an local folder where SQL server has access. Run the ExpQuery.sql file.
The database trigger uses this stored procedure to export the code to the repository base.

If you want to use it for other purposes:
```
declare @fileName nvarchar(500) = 'c:\temp\myFile.csv'
,       @sql varchar(max)       = 'select * from #temp' -- any table
,       @headers smallint       = 0/1 -- 0 is no headers
,       @lineFeed smallint      = 0
,       @noTrim                 = 1
,       @separator varchar(1)   = ';'
,       @decode  smallint       = 0

exec <database>.dbo.ExportQuery @fileName, @sql, @headers, @lineFeed, @noTrim, @separator, @decode
```

## Git 
I have created on an remote server an git repository for every userdatabase in SQL Server. For all my internal projects I use gitlab as management tool. You can use your favorite tool in order to create an local working copy. The location where you create this local folder is needed later on.

## Baseline Powershell script
To start with the version control of the userdatabase you will need an baseline. The script I use is based on my preferences of course so you can adjust as you seem fit.

The script will create an folder structure for each userdatabase and for the master database. Because I use Linked Servers the master database is also needed. This is the lay-out.
- Database
  - Assemblies
  - Roles
  - Schemas
  - ServiceBroker
  - StoredProcedures
  - Tables
  - Triggers
  - UserDefinedFunctions
  - Users
  - Views

The script is called schema.ps1     


More to come...
