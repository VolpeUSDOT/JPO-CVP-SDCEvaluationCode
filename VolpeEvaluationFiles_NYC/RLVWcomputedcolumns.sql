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

DROP table If Exists HostVehicleDataRLVWLoc_1

SELECT *, geography::STGeomFromText('POINT(' + STR(Xdeg, 16, 12) 
	+ ' ' + STR(Ydeg, 16, 12) + ')', 4326) as [HostLocation],
	geography::STGeomFromText('POINT(' + STR(StopLineXdeg, 16, 12) 
	+ ' ' + STR(StopLineYdeg, 16, 12) + ')', 4326) as [StopLineLocation]
INTO HostVehicleDataRLVWLoc_1
from HostVehicleDataRLVW_1
Go

Drop table if exists StopLineDataRLVW_1

Go

Select 
	[BSMID]
      ,[Role]
      ,[EventID]
      ,[EventType]
      ,[SeqNum]
      ,[MyRFLevel]
      ,[Authenticated]
      ,[MsgCnt]
      ,[hostVehicleID] as VehicleID
	  ,[intersectionid]
	  ,[lanesetlaneid]
      ,[AccuracySemiMajor]
      ,[AccuracySemiMinor]
      ,[AccuracyOrientation]
      ,[Transmission]
      ,[WheelAngle]
      ,[Along]
      ,[Alat]
      ,[Az]
      ,[Yaw]
      ,[Brake]
      ,[BrakeTraction]
      ,[BrakeABS]
      ,[BrakeSSCS]
      ,[BrakeBoos]
      ,[BrakeAUX]
      ,[Width]
      ,[Length]
      ,[X]
      ,[Y]
      ,[Z]
      ,[Time]
      ,[Speed]
      ,90 - 57.296*ATN2(LaneGeometry.STEndPoint().STY-LaneGeometry.STStartPoint().STY, LaneGeometry.STEndPoint().STX-LaneGeometry.STStartPoint().STX) as LaneAngle
      ,[class]
      ,[height]
      ,[mass]
      ,[VolpeID]
      ,[dummytime]
      ,[Xdeg]
      ,[Ydeg]
      ,[StopLineXdeg]
      ,[StopLineYdeg]
      ,[LaneWidth]
Into StopLineDataRLVW_1
From HostVehicleDataRLVW_1
where StopLineXdeg is not null
GO