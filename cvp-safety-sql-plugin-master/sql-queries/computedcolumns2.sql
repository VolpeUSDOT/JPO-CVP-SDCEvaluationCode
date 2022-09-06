IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'HV_Location'
          AND Object_ID = Object_ID(N'[hivedb].[dbo].[SafetyPilotTestData]'))
BEGIN
    ALTER TABLE [hivedb].[dbo].[SafetyPilotTestData]
	DROP COLUMN [HV_Location]
END

ALTER TABLE [hivedb].[dbo].[SafetyPilotTestData]
ADD [HV_Location] AS geography::STGeomFromText('POINT(' + STR(SafetyPilotTestData.HV_Longitude, 16, 12) + ' ' + STR(SafetyPilotTestData.HV_Latitude, 16, 12) + ')', 4326) PERSISTED

IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'RV_Location'
          AND Object_ID = Object_ID(N'[hivedb].[dbo].[SafetyPilotTestData]'))
BEGIN
    ALTER TABLE [hivedb].[dbo].[SafetyPilotTestData]
	DROP COLUMN [RV_Location]
END

ALTER TABLE [hivedb].[dbo].[SafetyPilotTestData]
ADD [RV_Location] AS geography::STGeomFromText('POINT(' + STR(SafetyPilotTestData.rv_longitude, 16, 12) + ' ' + STR(SafetyPilotTestData.rv_latitude, 16, 12) + ')', 4326) PERSISTED
