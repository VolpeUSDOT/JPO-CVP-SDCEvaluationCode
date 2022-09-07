USE NYCDB

--IF EXISTS(SELECT 1 FROM THEADB.sys.columns 
--          WHERE Name = N'Location'
--          AND Object_ID = Object_ID(N'THEADB.dbo.Volpe_SentBSM_interpedEventData'))
--BEGIN
--    ALTER TABLE THEADB.dbo.Volpe_SentBSM_interpedEventData
--	DROP COLUMN [Location]
--END

--ALTER TABLE THEADB.dbo.Volpe_SentBSM_interpedEventData
--ADD [Location] AS geography::STGeomFromText('POINT(' + STR(coredatalong, 16, 12) 
--											   + ' ' + STR(coredatalat, 16, 12) + ')', 4326) PERSISTED

DROP table If Exists HostVehicleDataLoc

SELECT *,
	geography::STGeomFromText('POINT(' + STR(Xdeg, 16, 12) 
	+ ' ' + STR(Ydeg, 16, 12) + ')', 4326) as [Location]
INTO HostVehicleDataLoc
from HostVehicleData
Go

--IF EXISTS(SELECT 1 FROM THEADB.sys.columns 
--          WHERE Name = N'Location'
--          AND Object_ID = Object_ID(N'THEADB.dbo.Volpe_ReceivedBSM_interpedEventData'))
--BEGIN
--    ALTER TABLE THEADB.dbo.Volpe_ReceivedBSM_interpedEventData
--	DROP COLUMN [Location]
--END

--ALTER TABLE THEADB.dbo.Volpe_ReceivedBSM_interpedEventData
--ADD [Location] AS geography::STGeomFromText('POINT(' + STR(coredatalong, 16, 12) 
--										       + ' ' + STR(coredatalat, 16, 12) + ')', 4326) PERSISTED

DROP table if exists TargetVehicleDataLoc

SELECT *,
	geography::STGeomFromText('POINT(' + STR(Xdeg, 16, 12) 
	+ ' ' + STR(Ydeg, 16, 12) + ')', 4326) as [Location]
INTO TargetVehicleDataLoc
from TargetVehicleData

