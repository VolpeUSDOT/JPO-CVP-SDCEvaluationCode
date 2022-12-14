INSERT INTO ---updated on 01/26/2022
NYCDB.dbo.VolpeDA_SpeedCompliance2


SELECT a.VolpeID ,a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, b.Class AS VehClass,a.TimeBin,a.WeatherCond,b.Speed,b.Along AS Ax,b.Brake,a.DummyTime,
BrakeReactTime_s,meanSpeed,minSpeed,maxSpeed, meanAx, minAx
,(Speed - 11.176) AS postedDeltaSpeed -- 25mph for speed & curve-speed compliances and 0 for workzone-speed conpliance
,(Speed - minSpeed) AS minDeltaSpeed
,CASE WHEN (minSpeedTime - WarningStartTime)!=0 THEN (minSpeed-Speed)/(minSpeedTime - WarningStartTime) ELSE NULL END AS minSpeed_Ax
,CASE WHEN a.GoodData = 1 AND a.DataCountAfter_s >= 3 AND b.Speed BETWEEN 11.176 AND 24.587 THEN 1 ELSE 0 END UsefulEvent -- Speed & Curve-speed compliances
,DataCountBefore_s,DataCountAfter_s,maxSpeed_all,ExcessiveSpeed -- data use for 'GoodData'
FROM
(
	SELECT a.eventID AS EventID, a.VolpeID, b.hostVehicleID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.TimeBin, a.WeatherCond, a.dummytime AS DummyTime, a.ExcessiveSpeed
	, BrakeReactTime_s,meanSpeed,minSpeed,maxSpeed, meanAx, minAx, DataCountAfter_s, DataCountBefore_s, maxSpeed_all
	, CASE WHEN a.DataCountBefore_s <= 20 AND a.DataCountAfter_s <= 10 AND a.maxSpeed_all <= 24.5872 AND a.ExcessiveSpeed = 0 
		THEN 1 ELSE 0 END GoodData
	, MIN(CASE WHEN a.EventID = b.EventID AND a.minSpeed = b.Speed THEN b.Time ELSE NULL END) minSpeedTime
	FROM
	(
		SELECT a.eventID AS EventID, a.VolpeID, b.hostVehicleID, a.WarningStartTime, a.WarningType, 
		a.Control, a.Active, a.TimeBin, a.WeatherCond, a.dummytime AS DummyTime, CAST(a.ExcessiveSpeed as int) AS ExcessiveSpeed,
		--MAX(ABS(Yaw*0.0174)) maxYawRate_RpS, 			
		CASE 
			WHEN Max(ABS(b.Yaw*0.0174)) > 0.22 THEN 1 
			WHEN Max(ABS(b.Yaw*0.0174)) <= 0.22 THEN 0 ELSE NULL END CurveSpeedRoad,
		MIN(b.Time) minTime, MAX(b.Time) maxTime, MAX(Speed) maxSpeed_all,
		SUM(CASE WHEN b.time < a.WarningStartTime THEN 1 else 0 end) AS DataCountBefore_s,
		SUM(CASE WHEN b.time > a.WarningStartTime THEN 1 else 0 end) AS DataCountAfter_s
		--After Alert
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND (b.Brake = '78' OR b.Brake = '88') THEN b.Time ELSE NULL END) - a.WarningStartTime AS BrakeReactTime_s
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Speed ELSE NULL END) meanSpeed
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Speed ELSE NULL END) minSpeed
		, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Speed ELSE NULL END) maxSpeed
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Along < 0 THEN b.Along ELSE NULL END) meanAx
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Along < 0 THEN b.Along ELSE NULL END) minAx
		--, COUNT(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Time ELSE NULL END) DataCount
		FROM 
		(	SELECT *, CASE WHEN GrpID = 20 THEN 1 ELSE 0 END 'Control' 
			FROM NYCDB.dbo.AllWarningEvent
			WHERE TimeBin NOT like '2020%' AND ((grpid = 20 and active = 0) OR Grpid > 20) --Remove 2020, control-active, and test events
		) a
		LEFT JOIN [NYCDB].[dbo].[HostVehicleData] b
		ON a.EventID = b.EventID AND b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10  --- timeb4 and/or after may not be samiliar pattern
		WHERE a.WarningType = 'Spdcomp' 		-- 'Spdcomp'; 'Cspdomp'; 'SpdcompWZ'
		GROUP BY a.eventID, a.VolpeID, b.hostVehicleID, a.WarningStartTime, a.WarningType, 
		a.Control, a.Active, a.TimeBin, a.WeatherCond, a.dummytime, a.ExcessiveSpeed
	) a
	LEFT JOIN NYCDB.dbo.HostVehicleData b
	ON a.EventID = b.EventID AND b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10
	GROUP BY a.eventID, a.VolpeID, b.hostVehicleID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.TimeBin, a.WeatherCond, a.dummytime, a.ExcessiveSpeed
	, BrakeReactTime_s,meanSpeed,minSpeed,maxSpeed, meanAx, minAx, DataCountAfter_s,DataCountBefore_s,maxSpeed_all
) a	
LEFT JOIN NYCDB.dbo.HostVehicleData b
ON a.EventID = b.EventID AND round(a.WarningStartTime,1) = b.Time
Order by UsefullEvent desc

--NOTICE: Addition filter conditions: Speeds, Ax, etc... (lower & upper limit), data available after warn (DataCount)...
---CurveSpeed and Speed Compliance: Speed between 25 and 55; AND datacount after warn is >= 4sec
--WorkZone Spee compliance: Speed between 10 and 55; AND datacount after warn is >= 4sec

-- When analyze V2I Ax, meanAx, apply ABS(Ax) < 5.5 m/s^2