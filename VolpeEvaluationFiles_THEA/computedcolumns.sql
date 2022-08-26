USE THEADB_V2

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

DROP table If Exists Volpe_SentBSM_interpedEventDataLoc

SELECT *,
	geography::STGeomFromText('POINT(' + STR(Longitude, 16, 12) 
	+ ' ' + STR(Latitude, 16, 12) + ')', 4326) as [Location]
INTO Volpe_SentBSM_interpedEventDataLoc
from Volpe_SentBSM_interpedEventData

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

DROP table if exists Volpe_ReceivedBSM_interpedEventDataLoc

SELECT *,
	geography::STGeomFromText('POINT(' + STR(Longitude, 16, 12) 
	+ ' ' + STR(Latitude, 16, 12) + ')', 4326) as [Location]
INTO Volpe_ReceivedBSM_interpedEventDataLoc
from Volpe_ReceivedBSM_interpedEventData

