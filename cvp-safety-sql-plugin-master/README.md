# cvp-safety-sql-plugin
Connected Vehicle Project - Volpe Safety Evaluation Team - SQL plugin

The CVP VSET SQL CLR Integration DLL that will help evaluate CVP datasets.

contact persons:
- Vyach Mayorskiy (dev)
- Bjorn Kuiper (dev)
- Andy Lam (sme)
- Wassim Najm (pm)

# information
The solution is maintained using VS2019

# SQL CLR DLL
The SqlSdcLibrary folder and SqlSdcLibrary.sln solution contains the SQL CLR DLL project to create the SQL CLR DLL that can be loaded into an SQL instance.

# web-poc
The Web-Prototype folder and Prototype.sln solution contains an web proof-of-concept with WEB-API (.net CORE) and client to visualize data (vehicles) over time using Esri Javascript API

supporting urls:
https://github.com/microsoft/sql-server-samples/tree/master/samples/features/json/todo-app/dotnet-rest-api
https://docs.microsoft.com/en-us/aspnet/core/tutorials/first-web-api?view=aspnetcore-3.0&tabs=visual-studio

As a developer, to execute:
$ donet watch run

As a developer, to publish the web prototype as a standalone executable:
$ dotnet publish