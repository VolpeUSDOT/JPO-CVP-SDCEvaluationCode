IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'HostLocation'
          AND Object_ID = Object_ID(N'dbo.sampleBSMDataFCW20190806_remote'))
BEGIN
    ALTER TABLE sampleBSMDataFCW20190806_remote
	DROP COLUMN [HostLocation]
END

ALTER TABLE sampleBSMDataFCW20190806_remote
ADD [HostLocation] AS geography::STGeomFromText('POINT(' + STR(sampleBSMDataFCW20190806_remote.hostlongitude, 16, 12) + ' ' + STR(sampleBSMDataFCW20190806_remote.hostlatitude, 16, 12) + ')', 4326) PERSISTED


IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'Location'
          AND Object_ID = Object_ID(N'dbo.sampleBSMDataFCW20190806_remote'))
BEGIN
    ALTER TABLE sampleBSMDataFCW20190806_remote
	DROP COLUMN [Location]
END

ALTER TABLE sampleBSMDataFCW20190806_remote
ADD [Location] AS geography::STGeomFromText('POINT(' + STR(sampleBSMDataFCW20190806_remote.longitude, 16, 12) + ' ' + STR(sampleBSMDataFCW20190806_remote.latitude, 16, 12) + ')', 4326) PERSISTED
