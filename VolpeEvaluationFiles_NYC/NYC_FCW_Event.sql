SELECT a.*
,CASE 
	WHEN (RV_LatPosition IS NULL OR RV_LongPosition IS NULL) THEN 0
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Center' THEN 1
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Left' THEN 2
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Right' THEN 3
	WHEN (RV_LongPosition = 'Behind' OR RV_LongPosition = 'Beside') THEN 4	
	ELSE NULL END RVLocation
INTO #FcwTemp7
FROM
(	SELECT a.*,
	CASE WHEN (b.RV_Speed-b.HV_Speed) < 0 THEN -(b.Range - 0.5*(HV_Length + RV_Length))/(b.RV_Speed-b.HV_Speed) ELSE NULL END AS TTC_s,
	b.RV_Speed, b.LatRange, b.LongRange, ABS(b.HV_Heading - b.RV_Heading) AS deltaHeading --RelLongLocation, RelLatLocation, count(*)
	,CASE 
		WHEN LongRange > (0.5*(HV_Length + RV_Length)) THEN 'Front'
		WHEN LongRange < -(0.5*(HV_Length + RV_Length)) THEN 'Behind'		
		WHEN LongRange BETWEEN -(0.5*(HV_Length + RV_Length)) AND (0.5*(HV_Length + RV_Length)) THEN 'Beside'
		ELSE NULL END RV_LongPosition		
	,CASE 
		WHEN LatRange BETWEEN -(0.5*(HV_Width + RV_Width)+0.305) AND (0.5*(HV_Width + RV_Width)+0.305) THEN 'Center'
		WHEN latRange < -(0.5*(HV_Width + RV_Width)+0.305) THEN 'Left'
		WHEN latRange > (0.5*(HV_Width + RV_Width)+0.305) THEN 'Right'
		ELSE NULL END RV_LatPosition
	,CASE WHEN (b.RV_Speed-b.HV_Speed) < -1.12 THEN 1 ELSE 0 END AS ClosingInRV
	,b.Range, (b.RV_Speed-b.HV_Speed) AS RangeRate
	,CASE WHEN b.HV_Speed > 0 THEN b.Range/b.HV_Speed ELSE NULL END AS Headway
	,CASE
		WHEN b.RV_Speed <= 1.12 THEN 'LVS'
		WHEN a.RV_Ax < -0.5 THEN 'LVD' 
		WHEN a.RV_Ax > 0.5 THEN 'LVA'
		WHEN a.RV_Ax BETWEEN -0.5 AND 0.5 THEN 'LVM'
		ELSE NULL END LeadVehState
	,0.5*(HV_Width + RV_Width) AS LatThreshold
	,0.5*(HV_Length + RV_Length) AS LongThreshold
	FROM 
	(	Select a.*, b.Speed, b.Along AS Ax, b.class AS VehClass,
		c.Along RV_Ax, c.Brake AS RV_Brake, c.Z AS DeltaElevation,
		CASE WHEN GrpID = 20 THEN 1 ELSE 0 END 'Control',
		CAST((	CASE 
					WHEN b.Brake = '00' THEN 0 
					WHEN b.Brake = '78' OR b.Brake = '88' THEN 1 
				ELSE NULL END) AS tinyint) AS Brake
		FROM [NYCDB].[dbo].[AllWarningEvent] a
		LEFT JOIN NYCDB.dbo.HostVehicleData b 
		ON a.eventid = b.EventID AND round(a.WarningStartTime,1) = round(b.Time,1)
		LEFT JOIN NYCDB.dbo.TargetVehicleData c
		ON b.eventid = c.EventID AND round(b.Time,1) = round(c.Time,1)
		WHERE TimeBin NOT like '2020%' AND ((grpid = 20 and active = 0) OR Grpid > 20) --AND a.WarningType = 'Fcw'
	) a
	LEFT JOIN [NYCDB].[dbo].[Volpe_NYC_Veh_Event_Kinematics] b
	ON a.HostVehID = b.hostVehicleID AND a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND round(a.WarningStartTime,1) = ROUND(b.Time,1)
	WHERE a.WarningType = 'FCW'
) a
Order by RVLocation


--INSERT INTO NYCDB.dbo.VolpeDA_FCW_Temp
SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.VehClass, a.TimeBin, a.WeatherCond, 
a.Speed, a.Range, a.RangeRate, a.Brake, a.Ax, a.TTC_s, a.Headway, a.RV_Speed, a.RV_Ax, a.LeadVehState, a.DummyTime, a.BrakeStartTime,
a.BrakeReactTime_s, a.meanSpeed, a.minSpeed, a.maxSpeed, a.meanAx, a.PeakAx, a.minTTC, a.minHeadway,
--BrakeOnset
CASE WHEN (b.RV_Speed-b.HV_Speed) < 0 THEN -(b.Range - 0.5*(HV_Length + RV_Length))/(b.RV_Speed-b.HV_Speed) ELSE NULL END AS BrakeOnsetTTC, 
b.Range AS BrakeOnsetRange, 
CASE WHEN b.HV_Speed > 0 THEN b.Range/b.HV_Speed ELSE NULL END AS BrakeOnsetHeadway
--Useful events
, CASE WHEN Good_Data = 1 AND UsefulCriteria = 1 THEN 1 ELSE 0 END UsefulEvent
--Addition data quality parameters:
,a.RVLocation, a.DataCountBefore_s, a.DataCountAfter_s, a.maxSpeed_all, a.maxRangeDiff, a.meanHVX, a.meanRVX, a.HV_PassRV, MaxRV_Speed_all, a.DeltaElevation
INTO #TempFianal
FROM
(
	SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.VehClass, a.TimeBin, a.WeatherCond,  
	a.Speed, a.Range, a.RangeRate, a.Ax, a.Brake, a.TTC_s, a.Headway, a.RV_Speed, a.RV_Ax, a.LeadVehState, a.DummyTime, a.DeltaElevation,
	b.BrakeReactTime_s, b.meanSpeed, b.minSpeed, b.maxSpeed, b.meanAx, b.PeakAx, b.minTTC, b.minHeadway, b.BrakeStartTime
	, CASE WHEN  b.DataCountBefore_s <= 7 AND b.DataCountAfter_s <= 10.1 AND b.maxRangeDiff < 50 
		AND (b.MeanHVX != 0 AND b.meanRVX != 0)  AND  b.maxSpeed_all < 24.5872 AND b.MaxRV_Speed_all < 24.5872
		THEN 1 ELSE 0 END Good_Data
	, CASE WHEN a.RVLocation = 1 AND ABS(a.DeltaElevation) <= 10 AND a.Range < 120 AND a.Speed BETWEEN 1.12 AND 24.5872 
		AND a.RangeRate <= 0.5 AND b.HV_PassRV IS NULL
		THEN 1 Else 0 END UsefulCriteria
	--Addition data quality parameters:
	,a.RVLocation, b.DataCountBefore_s, b.DataCountAfter_s, b.maxSpeed_all, b.maxRangeDiff, b.meanHVX, b.meanRVX, b.HV_PassRV, MaxRV_Speed_all
	FROM #FcwTemp7 a
	LEFT JOIN
	(	SELECT a.EventID, a.WarningStartTime, a.meanHVX, a.meanRVX, a.maxRangeDiff, a.HV_PassRV, a.minTTC, a.minHeadway, MaxRV_Speed_all,
 		--All data		
		MIN(b.Time) minTime, MAX(b.Time) maxTime, MAX(b.Speed) maxSpeed_all,
		COUNT(CASE WHEN b.time < a.WarningStartTime THEN b.time else NULL end)/10.0 AS DataCountBefore_s,
		COUNT(CASE WHEN b.time > a.WarningStartTime THEN b.Time else NULL end)/10.0 AS DataCountAfter_s
		--After Alert
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.Brake = '78' OR b.Brake = '88') 
			THEN b.Time ELSE NULL END) BrakeStartTime
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.Brake = '78' OR b.Brake = '88') 
			THEN b.Time ELSE NULL END) - a.WarningStartTime AS BrakeReactTime_s
		--, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND min(a.minTTC)
		--	THEN b.Time ELSE NULL END) minTTC_Time
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) meanSpeed
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) minSpeed
		, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) maxSpeed
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Along < 0 THEN b.Along ELSE NULL END) meanAx
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Along < 0 THEN b.Along ELSE NULL END) PeakAx
		--, COUNT(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Speed < 1.12 THEN b.Time ELSE NULL END)/10.0 AS RV_Stopped_sec
		, COUNT(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Time ELSE NULL END) DataCount
		FROM
		(	SELECT a.EventID, a.VolpeID, a.HostVehID, a.WarningStartTime, a.WarningType
			, AVG( ABS(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.HVX ELSE NULL END) ) meanHVX --- check whether x, y are all zero
			, AVG( ABS(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.RVX ELSE NULL END) ) meanRVX --- check whether x, y are all zero
			, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.RangeDiff ELSE NULL END) maxRangeDiff
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.RV_Speed-b.HV_Speed) < 0 
				THEN -(b.Range - 0.5*(HV_Length + RV_Length))/(b.RV_Speed-b.HV_Speed) ELSE NULL END) AS minTTC
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.HV_Speed > 0 
				THEN b.Range/b.HV_Speed ELSE NULL END) AS minHeadway
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND (b.LongRange - a.LongThreshold) < 0 THEN b.Time ELSE NULL END) AS HV_PassRV -- -a.WarningStartTime AS HV_PassRV_Time_s
			, MAX(b.RV_Speed) MaxRV_Speed_all
			FROM #FcwTemp7 a
			LEFT JOIN 
			(	SELECT *, RangeDiff =  ABS( Range - LAG(Range) OVER(Partition by eventtype, volpeid order by time) )
				FROM [NYCDB].[dbo].Volpe_NYC_Veh_Event_Kinematics 
			) b
			ON a.HostVehID = b.hostVehicleID AND a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND b.Time BETWEEN a.WarningStartTime - 100 and a.WarningStartTime + 100
			GROUP BY a.EventID, a.VolpeID, a.HostVehID, a.WarningStartTime, a.WarningType
		) a
		LEFT JOIN [NYCDB].[dbo].HostVehicleData b
		ON a.EventID = b.EventID AND b.Time BETWEEN a.WarningStartTime - 100 AND a.WarningStartTime + 100
		GROUP BY a.EventID, a.WarningStartTime, a.meanHVX, a.meanRVX, a.maxRangeDiff, a.HV_PassRV, a.minTTC, a.minHeadway, MaxRV_Speed_all
	) b
	ON a.EventID = b.EventID
) a --where Good_Data = 1 AND UsefulCriteria = 1
LEFT JOIN [NYCDB].[dbo].Volpe_NYC_Veh_Event_Kinematics b
ON a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND a.BrakeStartTime = b.Time
ORDER BY a.VolpeID



--UPDATE LVS Events due to RV Speed issues:
INSERT INTO NYCDB.dbo.VolpeDA_FCW
SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.VehClass, a.TimeBin, a.WeatherCond, 
a.Speed, a.Range, b.RangeRate2, a.Brake, a.Ax, b.TTC2, a.Headway, b.RV_Speed2, a.RV_Ax, b.LeadVehState2, a.DummyTime, a.BrakeStartTime,
a.BrakeReactTime_s, a.meanSpeed, a.minSpeed, a.maxSpeed, a.meanAx, a.PeakAx, b.minTTC2, a.minHeadway,
--BrakeOnset
b.BrakeOnsetTTC2, a.BrakeOnsetRange, a.BrakeOnsetHeadway
--Useful events
, CASE WHEN Good_Data2 = 1 AND UsefulCriteria2 = 1 THEN 1 ELSE 0 END UsefulEvent2
--Addition data quality parameters:
,a.RVLocation, a.DataCountBefore_s, a.DataCountAfter_s, a.maxSpeed_all, a.maxRangeDiff, a.meanHVX, a.meanRVX, a.HV_PassRV, a.DeltaElevation, b.MaxRV_Speed_all2
,CASE WHEN a.LeadVehState = 'LVS' THEN 1 ELSE 0 END OldLVS
FROM #TempFianal a 
LEFT JOIN
(	SELECT b.*
	, CASE WHEN  a.DataCountBefore_s <= 7 AND a.DataCountAfter_s <= 10.1 AND a.maxRangeDiff < 50 
		AND (a.MeanHVX != 0 AND a.meanRVX != 0)  AND  a.maxSpeed_all < 24.5872 AND b.MaxRV_Speed_all2 < 24.5872
		THEN 1 ELSE 0 END Good_Data2

	, CASE WHEN a.RVLocation = 1 AND ABS(a.DeltaElevation) <= 10 AND a.Range < 120 AND a.Speed BETWEEN 1.12 AND 24.5872 
		AND b.RangeRate2 <= 0.5 AND a.HV_PassRV IS NULL
		THEN 1 Else 0 END UsefulCriteria2
	FROM #TempFianal a 
	LEFT JOIN
	(	SELECT a.*
		,CASE WHEN LeadVehState = 'LVS' THEN
			CASE
				WHEN b.RV_SpeedNew <= 1.12 THEN 'LVS'
				WHEN b.Along < -0.5 THEN 'LVD' 
				WHEN b.Along > 0.5 THEN 'LVA'
				WHEN b.Along BETWEEN -0.5 AND 0.5 THEN 'LVM'
			END
		ELSE LeadVehState END AS LeadVehState2 
		,CASE WHEN LeadVehState = 'LVS' THEN (b.RV_SpeedNew-a.Speed) ELSE a.RangeRate END AS RangeRate2
		,CASE WHEN LeadVehState = 'LVS' THEN b.RV_SpeedNew ELSE a.RV_Speed END AS RV_Speed2
		,CASE WHEN LeadVehState = 'LVS' THEN
			CASE WHEN (b.RV_SpeedNew-a.Speed) < 0 THEN -(a.Range - 0.5*(a.HV_Length + b.RV_Length))/(b.RV_SpeedNew-a.Speed) ELSE NULL
		 END ELSE a.TTC_s END AS TTC2
		FROM
		(	SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.LeadVehState, a.Speed, a.Range, a.RangeRate, a.RV_Speed, a.TTC_s, b.HV_Length
			, MIN(	CASE WHEN LeadVehState = 'LVS' THEN
						CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.RV_SpeedNew-b.HV_Speed) < 0 
						THEN -(b.Range-0.5*(b.HV_Length + b.RV_Length))/(b.RV_SpeedNew-b.HV_Speed) ELSE NULL END
					ELSE a.minTTC END
				 ) AS minTTC2 
			, MAX(	CASE WHEN LeadVehState = 'LVS' THEN b.RV_SpeedNew ELSE b.RV_Speed END) MaxRV_Speed_all2 
			, MIN(	CASE WHEN LeadVehState = 'LVS' AND a.BrakeStartTime = b.Time THEN
						CASE WHEN (b.RV_SpeedNew-b.HV_Speed) < 0 THEN -b.Range/(b.RV_SpeedNew-b.HV_Speed) ELSE NULL 
					END ELSE a.BrakeOnsetTTC END
				 ) AS BrakeOnsetTTC2
			FROM #TempFianal a 
			LEFT JOIN 
			(	SELECT a.*, 
				SQRT(POWER((a.RVX-LagRVX),2) + POWER((a.RVY-LagRVY),2))/(Time - LagTime) AS RV_SpeedNew
				FROM 
				(	SELECT a.*, 
					lag(a.Time,3) OVER(PARTITION BY a.VolpeID, a.EventType ORDER BY a.Time) LagTime,
					lag(a.RVX,3) OVER(PARTITION BY a.VolpeID, a.EventType ORDER BY a.Time) LagRVX,
					lag(a.RVY,3) OVER(PARTITION BY a.VolpeID, a.EventType ORDER BY a.Time) LagRVY
					FROM [NYCDB].[dbo].Volpe_NYC_Veh_Event_Kinematics a
				) a  
			) b
			ON a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND b.Time BETWEEN a.WarningStartTime - 100 and a.WarningStartTime + 100
			--WHERE a.UsefulEvent = 1
			group by a.VolpeID, a.EventID, a.WarningStartTime, a.LeadVehState, a.Speed, a.Range, a.RangeRate, a.RV_Speed, a.TTC_s, b.HV_Length
		) a
		LEFT JOIN 
		(	SELECT a.*, CAST(a.Length as float)*.01 RV_Length,
			SQRT(POWER((a.RVX-LagRVX),2) + POWER((a.RVY-LagRVY),2))/(Time - LagTime) AS RV_SpeedNew
			FROM 
			(	SELECT a.*, a.X AS RVX, a.Y AS RVY,
				lag(Time,3) OVER(PARTITION BY a.EventID ORDER BY Time) LagTime,
				lag(a.X,3) OVER(PARTITION BY a.EventID ORDER BY Time) LagRVX,
				lag(a.Y,3) OVER(PARTITION BY a.EventID ORDER BY Time) LagRVY
				FROM [NYCDB].[dbo].[TargetVehicleData] a
				LEFT JOIN NYCDB.dbo.AllWarningEvent b
				ON a.EventID = b.eventid
			) a  --where VolpeID = 6248 and eventType = 'fcw'
		) b
		ON a.EventID = b.EventID AND ROUND(a.WarningStartTime,1) = ROUND(b.Time,1)
	) b
	ON a.EventID = b.EventID
) b
ON a.EventID = b.EventID
ORDER BY a.VolpeID