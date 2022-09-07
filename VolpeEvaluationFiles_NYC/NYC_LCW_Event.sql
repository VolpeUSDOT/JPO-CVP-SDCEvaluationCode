SELECT a.*
, ABS(latrange) - LatThreshold AS LatGap -- When LatGap < 0, it's overlapped, no gap between HV & RV
, CASE 
	WHEN ABS(LongRange) <= LongThreshold THEN NULL ---Overlapped
	WHEN LongRange < 0 THEN LongRange + LongThreshold ELSE LongRange - LongThreshold END AS LongGap  
, CASE 
	WHEN RV_Location = 0 THEN 0 --No target bsm data
	WHEN RV_Location = 1 THEN	--Behind-left
		CASE
			WHEN (ABS(latrange) - LatThreshold) <= 4.3 AND (ABS(LongRange) - 0.5*RV_Length) < 8.51 THEN 1	--blindspotzone & adjacent lane
			WHEN (ABS(latrange) - LatThreshold) <= 4.3 AND (ABS(LongRange) - 0.5*RV_Length) BETWEEN 8.51 AND 100 THEN 2	--closingzone & adjacent lane
		ELSE 11 END
	WHEN RV_Location = 2 THEN	--behind-right
		CASE
			WHEN (ABS(latrange) - LatThreshold) <= 4.3 AND (ABS(LongRange) - 0.5*RV_Length) < 8.51 THEN 1 ---change from 5.51 to 8.51 meters as NY spec
			WHEN (ABS(latrange) - LatThreshold) <= 4.3 AND (ABS(LongRange) - 0.5*RV_Length) BETWEEN 8.51 AND 100 THEN 2 ---change from 5.51 to 8.51 meters as NY spec
		ELSE 22 END
	WHEN RV_Location = 3 THEN 33 --behind-center
--	WHEN RV_Location = 3 THEN
--		CASE
--			WHEN LatRange < 0 AND (ABS(LongRange) - 0.5*RV_Length) < 8.51 THEN 1 
--			WHEN LatRange < 0 AND (ABS(LongRange) - 0.5*RV_Length) BETWEEN 8.51 AND 100 THEN 2
--			WHEN LatRange >= 0 AND (ABS(LongRange) - 0.5*RV_Length) < 8.51 THEN 1 ---change from 5.51 to 8.51 meters as NY spec
--			WHEN LatRange >= 0 AND (ABS(LongRange) - 0.5*RV_Length) BETWEEN 8.51 AND 100  THEN 2 ---change from 5.51 to 8.51 meters as NY spec
--		ELSE 33 END
	WHEN RV_Location IN(4,5) THEN --beside left/right
		CASE 
			WHEN (ABS(LatRange) - LatThreshold) <= 4.3 AND ( LongRange < 0 AND (LongRange + 0.5*RV_Length) < -0.51 ) THEN 1 --Beside & blindspot(left/right)
		ELSE 45 END
--	WHEN RV_Location = 6 AND LongRange < 0  AND (ABS(LongRange) - 0.5*RV_Length) < -0.51 THEN 1 --Beside(center)
	WHEN RV_Location = 6 THEN 66
	WHEN RV_Location = 7 THEN 77
ELSE NULL END AS RV_LanePosition
, CASE WHEN LongRange < 0 AND (LongRange + 0.5*RV_Length) < 0 THEN LongRange + 0.5*RV_Length ELSE NULL END AS LongGap2PilarHV
--, abs(LatRange) - 0.5*RV_Width AS RV_LatDist2Pilar
INTO #LcwTemp4
FROM
(	SELECT a.*,
	CASE 
	WHEN (RV_LatPosition IS NULL OR RV_LongPosition IS NULL) THEN 0	--No target bsm available
	WHEN RV_LongPosition = 'Behind' AND RV_LatPosition = 'Left' THEN 1
	WHEN RV_LongPosition = 'Behind' AND RV_LatPosition = 'Right' THEN 2
	WHEN RV_LongPosition = 'Behind' AND RV_LatPosition = 'Center' THEN 3
	WHEN RV_LongPosition = 'Beside' AND RV_LatPosition = 'Left' THEN 4
	WHEN RV_LongPosition = 'Beside' AND RV_LatPosition = 'Right' THEN 5
	WHEN RV_LongPosition = 'Beside' AND RV_LatPosition = 'Center' THEN 6	
	WHEN RV_LongPosition = 'Front' THEN 7
	ELSE NULL END RV_Location
	FROM
	(	SELECT a.*
		, CASE WHEN b.LongRange < 0 AND (b.LongRange+0.5*(HV_Length+RV_Length)) < 0 AND (b.HV_Speed-b.RV_Speed) < 0 
			THEN -(ABS(b.LongRange+0.5*(HV_Length+RV_Length)))/(b.HV_Speed-b.RV_Speed)
			ELSE NULL END AS RV_TTC_s
		, b.LatRange, b.LongRange, b.RV_Length, b.RV_Width
		, ABS(b.HV_Heading - b.RV_Heading) AS deltaHeading
		, CASE 
			WHEN LongRange > (0.5*(HV_Length + RV_Length)) THEN 'Front'
			WHEN LongRange < -(0.5*(HV_Length + RV_Length)) THEN 'Behind'		
			WHEN LongRange BETWEEN -(0.5*(HV_Length + RV_Length)) AND (0.5*(HV_Length + RV_Length)) THEN 'Beside'
			ELSE NULL END RV_LongPosition		
		, CASE 
			WHEN LatRange BETWEEN -(0.5*(HV_Width + RV_Width)) AND (0.5*(HV_Width + RV_Width)) THEN 'Center'
			WHEN latRange < -(0.5*(HV_Width + RV_Width)) THEN 'Left'
			WHEN latRange > (0.5*(HV_Width + RV_Width)) THEN 'Right'
			ELSE NULL END AS RV_LatPosition
		, CASE 
			WHEN (b.HV_Speed-b.RV_Speed) < -1.12 THEN 1 --closing
			WHEN (b.HV_Speed-b.RV_Speed) BETWEEN -1.12 AND 1.12 THEN 2 --following
			WHEN (b.HV_Speed-b.RV_Speed) > 1.12 THEN 3 --separating
			ELSE NULL END AS RV_DrivingState
		, b.Range, (b.HV_Speed-b.RV_Speed) AS RV_RangeRate
		, CASE WHEN b.RV_Speed > 0 AND (b.LongRange+0.5*(HV_Length+RV_Length)) < 0 THEN ABS(b.LongRange)/b.RV_Speed ELSE NULL END AS Headway
		, 0.5*(HV_Width + RV_Width) AS LatThreshold
		, 0.5*(HV_Length + RV_Length) AS LongThreshold
		, CASE 
			WHEN (b.HV_Heading BETWEEN 0 AND 160 AND b.RV_Heading BETWEEN b.HV_Heading+180-20 AND b.HV_Heading+180-20)
			OR (b.HV_Heading BETWEEN 160.001 AND 200 AND b.RV_Heading BETWEEN b.HV_Heading+180-20 AND b.HV_Heading-180+20)
			OR (b.HV_Heading BETWEEN 200.001 AND 360 AND b.RV_Heading BETWEEN b.HV_Heading-180-20 AND b.HV_Heading-180+20)
			THEN 1 ELSE 0 END RV_OppositeDirection
		FROM 
		(	SELECT a.*, b.Speed, b.Along AS Ax, b.Alat AS Ay, b.Yaw, b.class AS VehClass,
			CASE WHEN GrpID = 20 THEN 1 ELSE 0 END AS Control,
			--Round(b.Yaw*0.01745,2) YawRate, 
			--CASE WHEN abs(b.Yaw*0.01745) <= 0.025 THEN 1 
			--	 WHEN abs(b.Yaw*0.01745) > 0.025 THEN 0 ELSE NULL END StraightRd,
			CAST((	CASE 
						WHEN b.Brake = '00' THEN 0 
						WHEN b.Brake = '78' OR b.Brake = '88' THEN 1 
					ELSE NULL END) AS tinyint) AS Brake,
			CAST((	CASE 
						WHEN c.Brake = '00' THEN 0 
						WHEN c.Brake = '78' OR c.Brake = '88' THEN 1 
					ELSE NULL END) AS tinyint) AS RV_Brake
			, c.Along AS RV_Ax, c.Speed AS RV_Speed, c.Z AS DeltaElevation
			FROM [NYCDB].[dbo].[AllWarningEvent] a
			LEFT JOIN NYCDB.dbo.HostVehicleData b 
			ON a.eventid = b.EventID AND round(a.WarningStartTime,1) = round(b.Time,1)
			LEFT JOIN NYCDB.dbo.TargetVehicleData c 
			ON b.eventid = c.EventID AND round(b.Time,1) = round(c.Time,1)
			WHERE TimeBin NOT like '2020%' AND ((grpid = 20 and active = 0) OR Grpid > 20)  --temperary not available
		) a
		LEFT JOIN [NYCDB].[dbo].[Volpe_NYC_Veh_Event_Kinematics] b
		ON a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND round(a.WarningStartTime,1) = ROUND(b.Time,1)
		WHERE a.WarningType = 'LCW'
	) a
) a
Order by RV_Location



INSERT INTO NYCDB.dbo.VolpeDA_LCW
SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.VehClass, a.TimeBin, a.WeatherCond, 
a.Speed, a.LatGap, a.LongGap, a.RV_RangeRate, a.Brake, a.Ax, a.Ay, a.RV_TTC_s, a.RV_Speed, a.RV_Ax, a.DummyTime,
--after alert
a.meanSpeed, a.minSpeed, a.maxSpeed, a.minAy, a.minLatGap, a.minLongGap, a.minRV_TTC, a.RV_PassHV_AfterWarn--, a.meanAy, a.PeakAy
, CASE WHEN Good_Data = 1 AND UsefulCriteria = 1 THEN 1 ELSE 0 END UsefulAlert
--Addition data quality parameters:
, a.RV_Location,a.RV_LanePosition, a.DataCountBefore_s, a.DataCountAfter_s, a.maxSpeed_all, a.maxRangeDiff, a.meanHVX, a.meanRVX
, a.maxRV_Speed_all, a.DeltaElevation, a.RV_OppositeDirection
FROM
(	SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.VehClass, a.TimeBin, a.WeatherCond, 
	a.Speed, a.LatGap, a.LongGap, a.RV_RangeRate, a.Ax, a.Ay, a.Brake, a.RV_TTC_s, a.RV_Speed, a.RV_Ax, a.DummyTime, a.DeltaElevation, a.RV_OppositeDirection,
	--after alert
	b.meanSpeed, b.minSpeed, b.maxSpeed, b.minAy, b.minLatGap, b.minLongGap, b.minRV_TTC, b.RV_PassHV_AfterWarn
	 --, b.meanAy, b.PeakAy --may not meant much since there's mix sign covention between left or right target
	, CASE WHEN a.Speed BETWEEN 1.12 AND 24.5872 AND --a.RV_Speed BETWEEN 6.71 AND 24.587 AND
		b.maxRangeDiff < 50 AND b.DataCountBefore_s <= 10.1 AND b.DataCountAfter_s <= 10.1 AND b.MeanHVX > 0 AND b.meanRVX > 0 AND
		b.maxSpeed_all <= 24.5872 AND b.maxRV_Speed_all <= 24.5872 THEN 1 ELSE 0 END Good_Data
	, CASE WHEN ((a.RV_LanePosition = 1 AND a.LatGap > 0) OR (a.RV_LanePosition = 2 AND a.LatGap > 0 AND a.RV_TTC_s < 5.5))
		AND ABS(a.DeltaElevation) <= 10 AND RV_OppositeDirection = 0
		THEN 1 Else 0 END UsefulCriteria
	--Addition data quality parameters:
	,a.RV_Location, a.RV_LanePosition, b.DataCountBefore_s, b.DataCountAfter_s, b.maxSpeed_all, b.maxRangeDiff, b.meanHVX, b.meanRVX, b.maxRV_Speed_all
	FROM #LcwTemp4 a
	LEFT JOIN
	(	SELECT a.EventID, a.WarningStartTime, a.meanHVX, a.meanRVX, a.maxRangeDiff, a.maxRV_Speed_all,
		a.minRV_TTC, a.minLatGap, a.minLongGap, a.RV_PassHV_AfterWarn,
 		--All data		
		MIN(b.Time) minTime, MAX(b.Time) maxTime, MAX(b.Speed) maxSpeed_all,
		COUNT(CASE WHEN b.time < a.WarningStartTime THEN b.time else NULL end)/10.0 AS DataCountBefore_s,
		COUNT(CASE WHEN b.time > a.WarningStartTime THEN b.Time else NULL end)/10.0 AS DataCountAfter_s
		--After Alert
		--, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND (b.Brake = '78' OR b.Brake = '88') 
		--	THEN b.Time ELSE NULL END) - a.WarningStartTime AS BrakeResponseTime_s
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Speed ELSE NULL END) meanSpeed
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Speed ELSE NULL END) minSpeed
		, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Speed ELSE NULL END) maxSpeed
		--, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Along < 0 THEN b.Along ELSE NULL END) meanAx
		--, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Along < 0 THEN b.Along ELSE NULL END) PeakAx
		
		, COUNT(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Time ELSE NULL END) DataCountAfterWarn
		
		, max(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND RV_Location IN(1,4) THEN b.Alat ELSE NULL END) maxAy ---left target
		, max(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND RV_Location IN(2,5) THEN b.Alat ELSE NULL END) minAy
		FROM
		(	SELECT a.EventID, a.VolpeID, a.HostVehID, a.WarningStartTime, a.WarningType, a.RV_Location 
			, MAX(b.RV_Speed) AS maxRV_Speed_all
			, AVG( ABS(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.HVX ELSE NULL END) ) AS meanHVX --- check whether x, y are all zero
			, AVG( ABS(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.RVX ELSE NULL END) ) AS meanRVX --- check whether x, y are all zero
			, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.RangeDiff ELSE NULL END)  AS maxRangeDiff

			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.LongRange < 0 AND (b.LongRange + a.LongThreshold) < 0 AND (b.RV_Speed-b.HV_Speed) < 0 
				THEN -(ABS(b.LongRange + a.LongThreshold))/(b.RV_Speed-b.HV_Speed) ELSE NULL END) AS minRV_TTC
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.LongRange > 0 THEN b.Time ELSE NULL END) AS RV_PassHV_AfterWarn -- -a.WarningStartTime AS HV_PassRV_Time_s
			
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN (abs(b.LatRange) - LatThreshold) ELSE NULL END) AS minLatGap -- if negative value, HV & RV are lateral overlap
			, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.LongRange < 0 THEN b.LongRange + a.LongThreshold ELSE NULL END) minLongGap --if positive, HV & RV are longitudinal overlap or RV passed HV
			FROM #LcwTemp4 a
			LEFT JOIN 
			(	SELECT *, RangeDiff =  ABS( Range - LAG(Range) OVER(Partition by eventtype, volpeid order by time) )
				FROM [NYCDB].[dbo].Volpe_NYC_Veh_Event_Kinematics 
			) b
			ON a.HostVehID = b.hostVehicleID AND a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND b.Time BETWEEN a.WarningStartTime - 100 and a.WarningStartTime + 100
			GROUP BY a.EventID, a.VolpeID, a.HostVehID, a.WarningStartTime, a.WarningType, a.RV_Location 
		) a
		LEFT JOIN [NYCDB].[dbo].HostVehicleData b
		ON a.EventID = b.EventID AND b.Time BETWEEN a.WarningStartTime - 100 AND a.WarningStartTime + 100
		GROUP BY a.EventID, a.WarningStartTime, a.meanHVX, a.meanRVX, a.maxRangeDiff, a.RV_PassHV_AfterWarn, a.maxRV_Speed_all,
		a.minRV_TTC, a.minLatGap, a.minLongGap, RV_PassHV_AfterWarn
	) b
	ON a.EventID = b.EventID
) a --where Good_Data = 1 AND UsefulCriteria = 1
ORDER BY a.VolpeID



