CREATE TABLE THEADB_V2.dbo.Volpe_Thea_ERDW_Log2
(
	EventID				INT NOT NULL,
	HostVehID			VARCHAR(50) NOT NULL,
	HV_ID				BIGINT NOT NULL,
	StartTime			DATETIME NOT NULL,	
	WarningType			VARCHAR(50) NOT NULL,	
	ERDWSpeed_mph		INT NOT NULL,	
	HV_OnPath			TINYINT NULL,
	Speed				FLOAT NULL,	
	SpeedViolation_mph	FLOAT NULL,
	maxSpeed			FLOAT NULL,
	minSpeed			FLOAT NULL,
	meanSpeed			FLOAT NULL,	
	meanAx				FLOAT NULL,
	peakAx				FLOAT NULL,
	BrakeResponseTime	FLOAT NULL
	PRIMARY KEY (HostVehId, StartTime)
)

INSERT INTO THEADB_V2.dbo.Volpe_Thea_ERDW_Log2
SELECT a.*,
b.maxSpeed, b.minSpeed, b.meanSpeed, b.meanAx, b.peakAx, b.BrakeResponseTime
FROM
(
	SELECT a.EventID, a.HostVehID, a.HV_ID, a.StartTime, a.WarningType, a.ERDWSpeed ERDWSpeed_mph, a.HV_OnPath, a.Speed, a.SpeedViolation_mph
	FROM
	(	---individual event
		Select a.*,
		CASE 
			WHEN (Longitude > -82.4445 AND bsmElevation < -7) THEN 4 --over/underpass
			WHEN Latitude < 27.9524 THEN 3 --no longer on ramp/
			WHEN (cast(speed as float)*2.237 - cast(ERDWSpeed as float)) <= 0 THEN 2 -- under advisory speed	
			WHEN (cast(speed as float)*2.237 - cast(ERDWSpeed as float)) > 0 THEN 1 -- above advisory speed
			ELSE NULL END HV_OnPath, -- bsm not available
		DATEDIFF(ms,StartTime, Time)/1000.0 AS deltaTime,
		cast(speed as float)*2.237 - cast(ERDWSpeed as float) SpeedViolation_mph
		FROM
		(
			Select row_number() over (Partition by EventID order by a.Time) RowIndex, a.*
			FROM
			(
				SELECT a.EventID, a.HostVehID, a.HV_ID, a.StartTime, a.WarningType, a.Latitude, a.Longitude, a.DriverWarn, a.IsControl, a.IsDisabled, a.ERDWSpeed, 
				b.Time, b.Speed, b.Heading bsmHeading, b.Elevation bsmElevation, b.Latidute bsmLat, b.Longitude bsmLong, b.Brake
				FROM [THEADB_V2].[dbo].[Volpe_Thea_All_Warning_07312020] a
				LEFT JOIN [THEADB_V2].[dbo].Volpe_Thea_SentBsm b
				ON a.HostVehID = b.HostVehID AND b.time BETWEEN  a.StartTime AND DATEADD(s,3,a.StartTime) -- looking within 3 seconds of bsm data
				WHERE a.Warningtype = 'ERDW'
			) a	
		) a
		where RowIndex = 1 ---select 1st available data point from sent bsm
	) a
	--WHERE HV_OnPath = 1 --travelled above advisory speed
) a
LEFT JOIN 
(
	-- 5 second-window after alert started
	SELECT a.EventID, a.HostVehID, a.StartTime, a.WarningType,
	Max(b.Speed) maxSpeed,
	Min(b.Speed) minSpeed,
	AVG(b.speed) meanSpeed,
	AVG(CASE WHEN b.Ax < 0 THEN Ax ELSE NULL END) meanAx,
	MIN(CASE WHEN b.Ax < 0 THEN Ax ELSE NULL END) peakAx,
	MIN(CASE WHEN b.Brake = 1 THEN a.Time ELSE NULL END) BrakeStartTime,
	DATEDIFF(ms, min(StartTime), MIN(CASE WHEN a.Brake = 1 THEN a.Time ELSE NULL END))/1000.0 AS BrakeResponseTime
	FROM
	(	---individual event
		Select a.*,
		CASE 
			WHEN (Longitude > -82.4445 AND bsmElevation < -7)  THEN 4 --over/underpass
			WHEN Latitude < 27.9524 THEN 3 --no longer on ramp/
			WHEN (cast(speed as float)*2.237 - cast(ERDWSpeed as float)) <= 0 THEN 2 -- under advisory speed	
			WHEN (cast(speed as float)*2.237 - cast(ERDWSpeed as float)) > 0 THEN 1 -- above advisory speed
			ELSE NULL END HV_OnPath, -- bsm not available
		DATEDIFF(ms,StartTime, Time)/1000.0 AS deltaTime,
		cast(speed as float)*2.237 - cast(ERDWSpeed as float) SpeedViolation_mph
		FROM
		(
			Select row_number() over (Partition by EventID order by a.Time) RowIndex, a.*
			FROM
			(
				SELECT a.EventID, a.HostVehID, a.HV_ID, a.StartTime, a.WarningType, a.Latitude, a.Longitude, a.DriverWarn, a.IsControl, a.IsDisabled, a.ERDWSpeed, 
				b.Time, b.Speed, b.Heading bsmHeading, b.Elevation bsmElevation, b.Latidute bsmLat, b.Longitude bsmLong, b.Brake
				FROM [THEADB_V2].[dbo].[Volpe_Thea_All_Warning_07312020] a
				LEFT JOIN [THEADB_V2].[dbo].Volpe_Thea_SentBsm b
				ON a.HostVehID = b.HostVehID AND b.time BETWEEN  a.StartTime AND DATEADD(s,3,a.StartTime) -- within 3 seconds.
				WHERE a.Warningtype = 'ERDW'
			) a	
		) a
		where RowIndex = 1 
	) a
	LEFT JOIN [THEADB_V2].[dbo].Volpe_Thea_SentBsm b
	ON a.HostVehID = b.HostVehID AND b.time BETWEEN  a.StartTime AND DATEADD(s,5,a.StartTime)
	GROUP BY a.EventID, a.HostVehID, a.StartTime, a.WarningType
) b
ON a.WarningType = b.WarningType AND a.eventID = b.eventID
ORDER BY a.HostVehID, a.StartTime


SELECT [EventID],[HostVehID],b.veh_id HV_ID,[StartTime], b.ParticipantCategory,
CASE 
	WHEN b.ParticipantCategory = 'All-Silent' THEN 0
	WHEN b.ParticipantCategory = 'All-Active' THEN 1
	WHEN b.ParticipantCategory = 'unknown_category' THEN 3
	WHEN b.ParticipantCategory = 'Silent-Active' AND a.StartTime BETWEEN b.FirstSilent AND b.LastSilent THEN 0
	ELSE 1 END IsActive,
[WarningType],[ERDWSpeed_mph],[HV_OnPath],[Speed],[SpeedViolation_mph],[maxSpeed],[minSpeed] ,[meanSpeed],[meanAx],[peakAx],[BrakeResponseTime]
FROM [THEADB_V2].[dbo].[Volpe_Thea_ERDW_Log2] a
LEFT JOIN [THEADB_V2].[dbo].[Volpe_Thea_VehicleParticipantCategories] b
ON a.HostVehID = b.vehicleID
WHERE HV_OnPath = 1
ORDER BY IsActive, ERDWSpeed_mph, EventID



Select IsActive, count(*)
From
(
	SELECT [EventID],[HostVehID],b.veh_id HV_ID,[StartTime], b.ParticipantCategory,
	CASE 
		WHEN b.ParticipantCategory = 'All-Silent' THEN 0
		WHEN b.ParticipantCategory = 'All-Active' THEN 1
		WHEN b.ParticipantCategory = 'unknown_category' THEN 3
		WHEN b.ParticipantCategory = 'Silent-Active' AND a.StartTime BETWEEN b.FirstSilent AND b.LastSilent THEN 0
		ELSE 1 END IsActive,
	[WarningType],[ERDWSpeed_mph],[HV_OnPath],[Speed],[SpeedViolation_mph],[maxSpeed] ,[meanSpeed],[meanAx],[peakAx],[BrakeResponseTime]
	FROM [THEADB_V2].[dbo].[Volpe_Thea_ERDW_Log2] a
	LEFT JOIN [THEADB_V2].[dbo].[Volpe_Thea_VehicleParticipantCategories] b
	ON a.HostVehID = b.vehicleID
	WHERE HV_OnPath = 1 
) a
--WHERE ParticipantCategory = 'Silent-Active'
Group by IsActive


