

/* set database permissions for allowing custom CLR */
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'clr enabled', 1
GO
RECONFIGURE
GO
sp_configure 'clr strict security', 0
GO
RECONFIGURE
GO

/* Set the database to use */
USE NYCDB

--alter database test set trustworthy on
--go

/* drop previously created functions */
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SqlClrDllVersion')  
   DROP FUNCTION SqlClrDllVersion;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'ToUtm')  
   DROP FUNCTION ToUtm;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Northing')  
   DROP FUNCTION Northing;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Easting')  
   DROP FUNCTION Easting;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'NorthOffset')  
   DROP FUNCTION NorthOffset;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'EastOffset')  
   DROP FUNCTION EastOffset;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Range')  
   DROP FUNCTION Range;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'RangeRate')  
   DROP FUNCTION RangeRate;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'TimeToCollision')  
   DROP FUNCTION TimeToCollision;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'LongRange')  
   DROP FUNCTION LongRange;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'LatRange')  
   DROP FUNCTION LatRange;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'RelLongRange')  
   DROP FUNCTION RelLongRange;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'RelLatRange')  
   DROP FUNCTION RelLatRange;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'PreciseRelativeLocation')  
   DROP FUNCTION PreciseRelativeLocation;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'TimeToIntersection')  
   DROP FUNCTION TimeToIntersection;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HVSlope')  
   DROP FUNCTION HVSlope;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'RVSlope')  
   DROP FUNCTION RVSlope;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'CalculateB')  
   DROP FUNCTION CalculateB;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'CalculateX')  
   DROP FUNCTION CalculateX;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'CalculateY')  
   DROP FUNCTION CalculateY;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HVTTIBasedOnDtI')  
   DROP FUNCTION HVTTIBasedOnDtI;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'RVTTIBasedOnDtI')  
   DROP FUNCTION RVTTIBasedOnDtI;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'DistanceToPointOfInterestInMeters')  
   DROP FUNCTION DistanceToPointOfInterestInMeters;  
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'TimeToPointOfInterest')  
   DROP FUNCTION TimeToPointOfInterest;  
GO

/* drop CRL */
IF EXISTS (SELECT name FROM sys.assemblies WHERE name = 'CLR')  
   DROP ASSEMBLY CLR;  
GO

/* register CLR */

CREATE ASSEMBLY CLR AUTHORIZATION dbo
FROM 'C:\sql-clr-dll\SqlSdcLibrary.dll'
--with permissions_set = unsafe -- unsafe
GO

/* register functions */
CREATE FUNCTION SqlClrDllVersion() RETURNS nvarchar(max)   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].SqlClrDllVersion
GO  

CREATE FUNCTION ToUtm(@point geography)
RETURNS TABLE (Northing float, Easting float, Zona nvarchar(1024))
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].ToUtm
GO

CREATE FUNCTION Northing(@point1 geography) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].Northing
GO  

CREATE FUNCTION Easting(@point1 geography) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].Easting
GO  

CREATE FUNCTION NorthOffset(@point1 geography, @point2 geography) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].NorthOffset
GO  

CREATE FUNCTION EastOffset(@point1 geography, @point2 geography) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].EastOffset
GO  

CREATE FUNCTION Range(@point1 geography, @point2 geography) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].Range
GO  

CREATE FUNCTION RangeRate(@scaledDRange float, @dt float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].RangeRate
GO  

CREATE FUNCTION TimeToCollision(@range float, @rangeRate float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].TimeToCollision
GO  

CREATE FUNCTION LongRange(@northOffset float, @eastOffset float, @heading float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].LongRange
GO  

CREATE FUNCTION LatRange(@range float, @longRange float, @northOffset float, @eastOffset float, @heading float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].LatRange
GO  

CREATE FUNCTION RelLongRange(@longRange float, @hvLength float, @rvLength float) RETURNS nvarchar(max)   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].RelLongRange
GO  

CREATE FUNCTION RelLatRange(@latRange float, @hvWidth float, @rvWidth float) RETURNS nvarchar(max)   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].RelLatRange
GO  

CREATE FUNCTION PreciseRelativeLocation(@hvHeading float, @rvHeading float, @relativeLongLocation nvarchar(max), @relativeLatLocation nvarchar(max), @hvLength float, @hvWidth float, @rvLength float, @rvWidth float, @longRange float, @latRange float) RETURNS nvarchar(max)   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].PreciseRelativeLocation
GO  

CREATE FUNCTION TimeToIntersection(@range float, @speed float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].TimeToIntersection
GO  

CREATE FUNCTION HVSlope(@hostHeading float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].HVSlope
GO  

CREATE FUNCTION RVSlope(@hvSlope float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].RVSlope
GO  

CREATE FUNCTION CalculateB(@northOffset float, @eastOffset float, @hvSlope float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].CalculateB
GO  

CREATE FUNCTION CalculateX(@b float, @hvSlope float, @rvSlope float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].CalculateX
GO  

CREATE FUNCTION CalculateY(@hvSlope float, @x float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].CalculateY
GO  

CREATE FUNCTION HVTTIBasedOnDtI(@x float, @y float, @hvSpeed float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].HVTTIBasedOnDtI
GO  

CREATE FUNCTION RVTTIBasedOnDtI(@eastOffset float, @x float, @northOffset float, @y float, @rvSpeed float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].RVTTIBasedOnDtI
GO  

CREATE FUNCTION DistanceToPointOfInterestInMeters(@hvLatitude float, @hvLongitude float, @xxLatitude float, @xxLongitude float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].DistanceToPointOfInterestInMeters
GO  

CREATE FUNCTION TimeToPointOfInterest(@distance float, @speed float) RETURNS float   
AS EXTERNAL NAME CLR.[SqlSdcLibrary.SqlFunctions].TimeToPointOfInterest
GO  
