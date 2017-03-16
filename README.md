# ssmsGit
SQL Server Management Studio Source Control with Git, the DevOps approach.

## Synopsis
This project is an collection of software and t-sql code in order to get youre SQL Server under version control without the need to install expensive tools like RedGate's solution for source control. All the code and assemblies are free to use.
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
