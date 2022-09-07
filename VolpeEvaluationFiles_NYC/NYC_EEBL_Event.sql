SELECT a.*, (abs(latrange) - LatThreshold) AS LatGap,
CASE 
	WHEN RVLocation = 0 THEN 0 --No target bsm
	WHEN RVLocation = 1 THEN 1 --Front, center
	WHEN RVLocation IN(2,3) AND abs(latRange) > LatThreshold+0.305 THEN 
		CASE 
			WHEN (abs(latrange) - LatThreshold) <= 3.6 THEN 2 --'Front, 1-lane over' --- 3.6 meters is an estimated lanewidth
			ELSE 3 END --Front, 2 or more lanes over
	WHEN RVLocation = 4 THEN 4 --behind/beside
	ELSE NULL END AS RV_LanePosition --unknown
INTO #FcwTemp10
FROM
(	SELECT a.*,
	CASE 
	WHEN (RV_LatPosition IS NULL OR RV_LongPosition IS NULL) THEN 0	--No target bsm available
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Center' THEN 1
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Left' THEN 2
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Right' THEN 3
	WHEN RV_LongPosition = 'Behind' OR RV_LongPosition = 'Beside' THEN 4	
	ELSE NULL END RVLocation
	FROM
	(	SELECT a.*,
		CASE WHEN (b.RV_Speed-b.HV_Speed) < 0 THEN -b.Range/(b.RV_Speed-b.HV_Speed) ELSE NULL END AS TTC_s,
		b.LatRange, b.LongRange, ABS(b.HV_Heading - b.RV_Heading) AS deltaHeading --RelLongLocation, RelLatLocation, count(*)
		,b.RV_Speed
		,CASE 
			WHEN LongRange > (0.5*(HV_Length + RV_Length)) THEN 'Front'
			WHEN LongRange < -(0.5*(HV_Length + RV_Length)) THEN 'Behind'		
			WHEN LongRange BETWEEN -(0.5*(HV_Length + RV_Length)) AND (0.5*(HV_Length + RV_Length)) THEN 'Beside'
			ELSE NULL END RV_LongPosition		
		,CASE 
			WHEN LatRange BETWEEN -(0.5*(HV_Width + RV_Width)+0.305) AND (0.5*(HV_Width + RV_Width)+0.305) THEN 'Center'
			WHEN latRange < -(0.5*(HV_Width + RV_Width)+0.305) THEN 'Left'
			WHEN latRange > (0.5*(HV_Width + RV_Width)+0.305) THEN 'Right'
			ELSE NULL END AS RV_LatPosition
		,CASE WHEN (b.RV_Speed-b.HV_Speed) < -1.12 THEN 1 ELSE 0 END AS ClosingInRV
		,b.Range, (b.RV_Speed-b.HV_Speed) AS RangeRate
		,CASE WHEN b.HV_Speed > 0 THEN b.Range/b.HV_Speed ELSE NULL END AS Headway
		,0.5*(HV_Width + RV_Width) AS LatThreshold
		,CASE
			WHEN RV_Speed <= 1.12 THEN 'LVS'
			WHEN RV_Ax < -0.5 THEN 'LVD' 
			WHEN RV_Ax > 0.5 THEN 'LVA'
			WHEN RV_Ax BETWEEN -0.5 AND 0.5 THEN 'LVM'
			ELSE NULL END LeadVehState
		FROM 
		(	Select a.*, b.Speed, b.Along AS Ax, b.class AS VehClass,
			CASE WHEN GrpID = 20 THEN 1 ELSE 0 END AS Control,
			--Round(b.Yaw*0.01745,2) YawRate, 
			--CASE WHEN abs(b.Yaw*0.01745) <= 0.025 THEN 1 
			--	 WHEN abs(b.Yaw*0.01745) > 0.025 THEN 0 ELSE NULL END StraightRd,
			CAST((	CASE 
						WHEN b.Brake = '00' THEN 0 
						WHEN b.Brake = '78' OR b.Brake = '88' THEN 1 
					ELSE NULL END) AS tinyint) AS HV_Brake,
			c.RV_Ax, c.DeltaElevation
			FROM [NYCDB].[dbo].[AllWarningEvent] a
			LEFT JOIN NYCDB.dbo.HostVehicleData b 
			ON a.eventid = b.EventID AND round(a.WarningStartTime,1) = round(b.Time,1)
			LEFT JOIN 
			(	Select a.EventID, a.WarningStartTime, min(c.Along) RV_Ax, max(c.brake) RV_Brake, min(abs(c.Z)) DeltaElevation
				FROM [NYCDB].[dbo].[AllWarningEvent] a
				LEFT JOIN NYCDB.dbo.TargetVehicleData c 
				ON a.eventid = c.eventid and c.time between a.WarningStartTime - 0.5 AND a.WarningStartTime + 0.5 -- some missing RV data @alert onset time
				GROUP BY a.EventID, a.WarningStartTime
			) c
			ON b.eventid = c.EventID 
			WHERE TimeBin NOT like '2020%' AND ((grpid = 20 and active = 0) OR Grpid > 20) --AND a.WarningType = 'EEBL'
		) a
		LEFT JOIN [NYCDB].[dbo].[Volpe_NYC_Veh_Event_Kinematics] b
		ON a.HostVehID = b.hostVehicleID AND a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND round(a.WarningStartTime,1) = ROUND(b.Time,1)
		WHERE a.WarningType = 'EEBL'
	) a
) a
Order by RVLocation



INSERT INTO NYCDB.dbo.VolpeDA_EEBL

SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, b.VehClass, a.TimeBin, a.WeatherCond, 
b.Speed, b.Range, b.RangeRate, b.HV_Brake, b.Ax, b.TTC_s, b.RV_Speed, b.RV_Ax, b.LeadVehState, a.DummyTime,
a.BrakeReactTime_s, a.meanSpeed, a.minSpeed, a.maxSpeed, a.meanAx, a.PeakAx, a.HV_Stopped_sec, a.minTTC, a.minHeadway,
--BrakeOnset C:
CASE WHEN (c.RV_Speed-c.HV_Speed) < 0 THEN -c.Range/(c.RV_Speed-c.HV_Speed) ELSE NULL END AS BrakeTTC, 
c.Range AS BrakeOnsetRange, 
CASE WHEN c.HV_Speed > 0 THEN c.Range/c.HV_Speed ELSE NULL END AS BrakeOnsetHeadway,

CASE WHEN a.GoodData = 1 AND maxRV_Speed_all <= 24.5872 AND a.maxRangeDiff < 50 AND a.MeanHVX > 0 AND b.RV_LanePosition IN(1,2) AND b.RV_Ax <= -3.5  
	THEN 1 ELSE 0 END UsefulEvent
,RVLocation, RV_LanePosition,a.DataCountBefore_s, a.DataCountAfter_s, a.maxSpeed_all, a.maxRangeDiff, meanHVX, a.DeltaElevation, maxRV_Speed_all
FROM
(	SELECT a.EventID, a.VolpeID, a. HostVehID, a.WarningStartTime, a.WarningType, 
	a.Control, a.Active, a.TimeBin, a.WeatherCond, a.DummyTime, GoodData,DataCountBefore_s,DataCountAfter_s, maxSpeed_all,
	a.BrakeReactTime_s, a.meanSpeed, a.minSpeed, a.maxSpeed, a.meanAx, a.PeakAx, a.HV_Stopped_sec, a.BrakeStartTime, a.DeltaElevation,
	AVG(abs(b.HVX)) meanHVX, AVG(abs(b.HVY)) meanHVY, --- check whether x, y are all zero
	AVG(abs(b.RVX)) meanRVX, AVG(abs(b.RVY)) meanRVY,
	MAX(b.RangeDiff) maxRangeDiff,
	MAX(b.RV_Speed) maxRV_Speed_all
	, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.RV_Speed-b.HV_Speed) < 0 
		THEN -b.Range/(b.RV_Speed-b.HV_Speed) ELSE NULL END) AS minTTC
	, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.HV_Speed > 0 
		THEN b.Range/b.HV_Speed ELSE NULL END) AS minHeadway
	FROM
	(	SELECT a.*,
		CASE WHEN DataCountBefore_s <= 7 AND DataCountAfter_s <= 10 AND maxSpeed_all <= 24.5872 AND DeltaElevation <= 10
			THEN 1 ELSE 0 END GoodData
		FROM
		(	SELECT a.eventID AS EventID, a.VolpeID, b.hostVehicleID AS HostVehID, a.WarningStartTime, a.WarningType, 
			a.Control, a.Active, a.TimeBin, a.WeatherCond, a.dummytime AS DummyTime, a.DeltaElevation,	
			CASE 
				WHEN Max(ABS(b.Yaw*0.0174)) > 0.22 THEN 1 
				WHEN Max(ABS(b.Yaw*0.0174)) <= 0.22 THEN 0 ELSE NULL END CurveSpeedRoad,
			MIN(b.Time) minTime, MAX(b.Time) maxTime, MAX(b.Speed) maxSpeed_all,
			COUNT(CASE WHEN b.time < a.WarningStartTime THEN b.time else NULL end)/10.0 AS DataCountBefore_s,
			COUNT(CASE WHEN b.time > a.WarningStartTime THEN b.Time else NULL end)/10.0 AS DataCountAfter_s
			--After Alert
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.Brake = '78' OR b.Brake = '88') 
				THEN b.Time ELSE NULL END) BrakeStartTime
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.Brake = '78' OR b.Brake = '88') THEN b.Time ELSE NULL END) - a.WarningStartTime AS BrakeReactTime_s
			, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) meanSpeed
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) minSpeed
			, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) maxSpeed
			, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Along < 0 THEN b.Along ELSE NULL END) meanAx
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Along < 0 THEN b.Along ELSE NULL END) PeakAx
			, COUNT(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Speed < 1.12 THEN b.Time ELSE NULL END)/10.0 AS HV_Stopped_sec
			--, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.RV_Speed-b.HV_Speed) < 0 THEN -b.Range/(b.RV_Speed-b.HV_Speed) ELSE NULL END) AS minTTC
			--, COUNT(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Time ELSE NULL END) DataCount
			FROM #FcwTemp10 a
			LEFT JOIN [NYCDB].[dbo].HostVehicleData b
			ON a.EventID = b.EventID AND b.Time BETWEEN a.WarningStartTime - 100 AND a.WarningStartTime + 100
			GROUP BY a.eventID,a.VolpeID,b.hostVehicleID,a.WarningStartTime,a.WarningType,a.Control,a.Active,a.TimeBin,a.WeatherCond,a.dummytime, DeltaElevation
		) a
	) a
	LEFT JOIN 
	(	SELECT *, RangeDiff =  ABS( Range - LAG(Range) OVER(Partition by eventtype, volpeid order by time) )
		FROM [NYCDB].[dbo].Volpe_NYC_Veh_Event_Kinematics 
	) b
	ON a.HostVehID = b.hostVehicleID AND a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND b.Time BETWEEN a.WarningStartTime and a.WarningStartTime + 5
	GROUP BY a.EventID, a.VolpeID, a.HostVehID, a.WarningStartTime, a.WarningType, 
	a.Control, a.Active, a.TimeBin, a.WeatherCond, a.DummyTime, GoodData,DataCountBefore_s,DataCountAfter_s, maxSpeed_all,
	a.BrakeReactTime_s, a.meanSpeed, a.minSpeed, a.maxSpeed, a.meanAx, a.PeakAx, a.HV_Stopped_sec, a.BrakeStartTime, a.DeltaElevation
) a
LEFT JOIN #FcwTemp10 b
ON a.EventID = b.EventID
LEFT JOIN [NYCDB].[dbo].Volpe_NYC_Veh_Event_Kinematics c
ON a.VolpeID = c.VolpeID AND a.WarningType = c.EventType AND a.BrakeStartTime = c.Time
ORDER BY a.VolpeID

