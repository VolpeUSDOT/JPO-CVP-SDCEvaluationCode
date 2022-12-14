SELECT a.*,
(abs(latrange) - LatThreshold) AS LatGap, 
(abs(longrange) - LongThreshold) AS LongGap, a.HostVehID HVID, a.VolpeID VolID
INTO #FcwTemp3
FROM
(	SELECT a.*,
	CASE 
	WHEN (RV_LatPosition IS NULL OR RV_LongPosition IS NULL) THEN 0	--No target bsm available
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Left' THEN 1
	WHEN RV_LongPosition = 'Front' AND RV_LatPosition = 'Right' THEN 2
	WHEN RV_LongPosition = 'Behind' THEN 3
	ELSE NULL END RVLocation
	FROM
	(	SELECT a.*,
		b.LatRange, b.LongRange, b.RV_Length, b.RV_Width, b.RV_Speed,
		b.HVTTI, b.RVTTI,-- b.TTI_LongRange_HV, b.TTI_LongRange_HV,
		ABS(b.HV_Heading - b.RV_Heading) AS deltaHeading
		,CASE 
			WHEN LongRange >= -(0.5*(HV_Length + RV_Width)) THEN 'Front'
			WHEN LongRange < -(0.5*(HV_Length + RV_Width)) THEN 'Behind' --- behind or late warn		
			ELSE NULL END RV_LongPosition
		,CASE 
			WHEN latRange < 0 THEN 'Left'
			WHEN latRange >= 0 THEN 'Right'
			ELSE NULL END AS RV_LatPosition
		,0.5*(HV_Width + RV_Length) AS LatThreshold
		,0.5*(HV_Length + RV_Width) AS LongThreshold
		,CASE 
			WHEN (b.HV_Heading BETWEEN 0 AND 160 AND b.RV_Heading BETWEEN b.HV_Heading+180-20 AND b.HV_Heading+180-20)
			OR (b.HV_Heading BETWEEN 160.001 AND 200 AND b.RV_Heading BETWEEN b.HV_Heading+180-20 AND b.HV_Heading-180+20)
			OR (b.HV_Heading BETWEEN 200.001 AND 360 AND b.RV_Heading BETWEEN b.HV_Heading-180-20 AND b.HV_Heading-180+20)
			THEN 1 ELSE 0 END RV_OppositeDirection

		FROM 
		(	SELECT a.EventID, a.VolpeID,a.HostVehID,a.TargetID,a.WarningType,a.WarningStartTime,a.Active,a.Sent,a.Heard,a.minSpdThreshold,a.GrpID,a.TimeBin,a.LocationBin, 
			a.WeatherCond, a.DummyTime, b.Brake,
			CASE
				WHEN b.Speed <= 1.12 THEN 'LVS'
				WHEN b.Brake = 1 OR b.Along <-0.49 THEN 'LVD' 
				WHEN b.Along BETWEEN -0.49 AND 0.49 THEN 'LVM' 
				WHEN b.Along > 0.49 THEN 'LVA'
			ELSE NULL END HostVehState,
			b.Speed, b.Along AS Ax, b.class AS VehClass,
			CASE WHEN GrpID = 20 THEN 1 ELSE 0 END AS Control,
			Round(b.Yaw*0.01745,2) HV_Rate, 
			Round(c.Yaw*0.01745,2) RV_Rate, 
			CASE WHEN abs(b.Yaw*0.01745) <= 0.025 THEN 1 
				 WHEN abs(b.Yaw*0.01745) > 0.025 THEN 0 ELSE NULL END HV_StraightRd,
			CASE WHEN abs(c.Yaw*0.01745) <= 0.025 THEN 1 
				 WHEN abs(c.Yaw*0.01745) > 0.025 THEN 0 ELSE NULL END RV_StraightRd,
			CAST((	CASE 
						WHEN b.Brake = '00' THEN 0 
						WHEN b.Brake = '78' OR b.Brake = '88' THEN 1 
					ELSE NULL END) AS tinyint) AS HV_Brake,
			CAST((	CASE 
						WHEN c.Brake = '00' THEN 0 
						WHEN c.Brake = '78' OR c.Brake = '88' THEN 1 
					ELSE NULL END) AS tinyint) AS RV_Brake
			, c.Along AS RV_Ax, b.Z AS HV_Z, c.Z AS DeltaElevation
			FROM [NYCDB].[dbo].[AllWarningEvent] a
			LEFT JOIN NYCDB.dbo.HostVehicleData b 
			ON a.eventid = b.EventID AND round(a.WarningStartTime,1) = round(b.Time,1)
			LEFT JOIN NYCDB.dbo.TargetVehicleData c 
			ON b.eventid = c.EventID AND round(b.Time,1) = round(c.Time,1)
			WHERE TimeBin NOT like '2020%' AND ((grpid = 20 and active = 0) OR Grpid > 20) 
		) a
		LEFT JOIN [NYCDB].[dbo].[Volpe_NYC_Veh_Event_Kinematics] b
		ON a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND round(a.WarningStartTime,1) = ROUND(b.Time,1)
		WHERE a.WarningType = 'IMA' --and a.VolpeID = 1553
	) a
) a --WHERE RV_Location > 0 AND a.HV_StraightRd = 1 AND a.RV_StraightRd = 1
--group by RV_Location
order by RVLocation

INSERT INTO NYCDB.dbo.VolpeDA_IMA
SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.VehClass, a.TimeBin, a.WeatherCond, 
a.Speed, a.LongRange, a.LatRange, a.Brake, a.Ax, a.HostVehState, a.HVTTI, a.RV_Speed, a.RV_Ax, a.RVTTI, a.DummyTime,
a.BrakeResponseTime_s, a.meanSpeed, a.minSpeed, a.maxSpeed, a.meanAx, a.PeakAx, a.HV_Stopped_s, a.RV_Stopped_s,
a.FirstEnterConflictZone, a.PostEncroachment
, CASE WHEN Good_Data = 1 AND UsefulCriteria = 1 THEN 1 ELSE 0 END UsefulEvent
--Addition data quality parameters:
, a.RVLocation, a.HV_StraightRd, a.RV_StraightRd, a.DeltaElevation, a.RV_OppositeDirection 
, a.HV_Turn, a.maxRangeDiff,a.DataCountBefore_s,a.DataCountAfter_s,a.maxSpeed_all, a.meanHVX, a.meanRVX, a.HV_MovingStatus, maxRV_Speed_all
FROM
(	SELECT a.VolpeID, a.EventID, a.WarningStartTime, a.WarningType, a.Control, a.Active, a.VehClass, a.TimeBin, a.WeatherCond, 
	a.Speed, a.LongRange, a.LatRange, a.Ax, a.HostVehState, a.Brake, a.HVTTI, a.RV_Speed, a.RV_Ax, a.RVTTI, a.DummyTime,
	b.BrakeResponseTime_s, b.meanSpeed, b.minSpeed, b.maxSpeed, b.meanAx, b.PeakAx, b.HV_Stopped_s, b.RV_Stopped_s, maxRV_Speed_all,
	b.FirstEnterConflictZone, b.PostEncroachment
	, CASE WHEN a.RVLocation IN (1,2) AND a.HV_StraightRd = 1 AND a.RV_StraightRd = 1 AND ABS(a.DeltaElevation) <= 10 AND 
		b.maxSpeed_all <= 24.5872 AND b.maxRangeDiff < 50 AND (b.MeanHVX > 0 AND b.meanRVX > 0) AND maxRV_Speed_all <= 24.5872 AND
		(b.DataCountBefore_s <= 10.1 AND b.DataCountAfter_s <= 10.1)
		THEN 1 ELSE 0 END Good_Data
	, CASE
		WHEN HV_Turn = 1 AND RVLocation != 1 THEN 0 -- HV turn right and RV not from left
		WHEN a.RV_OppositeDirection = 1 THEN 0 
		--WHEN b.HV_MovingStatus = 'StopRolling' AND RVTTI > 12 THEN 0 
		--WHEN ABS(LatRange) < 4.5 THEN 0 -- average car length
		ELSE 1	END UsefulCriteria
	--Addition data quality parameters:
	, a.RVLocation, a.HV_StraightRd, a.RV_StraightRd, a.DeltaElevation, a.RV_OppositeDirection 
	, b.HV_Turn, b.maxRangeDiff, b.DataCountBefore_s, b.DataCountAfter_s, b.maxSpeed_all, b.meanHVX, b.meanRVX, b.HV_MovingStatus
	FROM #FcwTemp3 a
	LEFT JOIN
	(	SELECT a.*,
		CASE 
			WHEN RV_CrossRV_Time > HV_CrossRV_Time THEN 'HV-RV'
			WHEN RV_CrossRV_Time < HV_CrossRV_Time THEN 'RV-HV'
			WHEN HV_CrossRV_Time > 0 THEN 'HV-N/A'
			WHEN RV_CrossRV_Time > 0 THEN 'RV-N/A'
			ELSE 'N/A' END FirstEnterConflictZone,
		CASE 
			WHEN RV_CrossRV_Time > HV_CrossRV_Time THEN RV_CrossRV_Time - HV_CrossRV_Time
			WHEN RV_CrossRV_Time < HV_CrossRV_Time THEN HV_CrossRV_Time - RV_CrossRV_Time 
			ELSE NULL END AS PostEncroachment,
		CASE	
			WHEN a.Speed <= 4.47 THEN 'StopRolling'
			WHEN a.Speed > 4.47 THEn 'Moving' ELSE NULL END 'HV_MovingStatus',
		CASE 
			WHEN a.maxYaw > 0.3 THEN 1 
			WHEN a.maxYaw < -0.3 THEN 2
			ELSE 0 END HV_Turn
		FROM
		(	SELECT a.EventID, a.WarningStartTime, a.Speed, a.meanHVX, a.meanRVX, a.maxRangeDiff,minHVSpeed, minRVspeed, minHVTTI, 
			minRVTTI, HV_CrossRV_Time, RV_CrossRV_Time, Range_HV@conflictZone, Range_RV@conflictZone, RV_Stopped_s, maxRV_Speed_all
 			--All data		
			, MAX(b.Speed) maxSpeed_all
			, COUNT(CASE WHEN b.time < a.WarningStartTime THEN b.time else NULL end)/10.0 AS DataCountBefore_s
			, COUNT(CASE WHEN b.time > a.WarningStartTime THEN b.Time else NULL end)/10.0 AS DataCountAfter_s
			--10 sec after alert
			, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.Yaw ELSE NULL END)*0.01745 maxYaw 
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Speed > 2.24 AND abs(b.Yaw) > 0 
				THEN 1/(b.Yaw*0.01745/b.Speed) else null end) minR
			, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Speed > 2.24 AND abs(b.Yaw) > 0 
				THEN 1/(b.Yaw*0.01745/b.Speed) else null end) maxR
			--5 sec after Alert
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND (b.Brake = '78' OR b.Brake = '88') 
				THEN b.Time ELSE NULL END) - a.WarningStartTime AS BrakeResponseTime_s
			, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) meanSpeed
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) minSpeed
			, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Speed ELSE NULL END) maxSpeed
			, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Along < 0 THEN b.Along ELSE NULL END) meanAx
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 AND b.Along < 0 THEN b.Along ELSE NULL END) PeakAx
			, SUM(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Speed < 1.12 THEN 1 ELSE NULL END)/10.0 AS HV_Stopped_s
			--, COUNT(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.Time ELSE NULL END) DataCount
			FROM
			(	SELECT a.EventID, a.VolpeID, a.HostVehID, a.WarningStartTime, a.WarningType, a.Speed 
				--5 sec after warning
				, AVG( ABS(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.HVX ELSE NULL END) ) meanHVX --- check whether x, y are all zero
				, AVG( ABS(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.RVX ELSE NULL END) ) meanRVX --- check whether x, y are all zero
				, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 5 THEN b.RangeDiff ELSE NULL END) maxRangeDiff
				--10 secs after warning
				, min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.HV_Speed ELSE NULL END) minHVSpeed
				, min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.RV_Speed ELSE NULL END) minRVspeed
				, min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.HVTTI ELSE NULL END) minHVTTI
				, Min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 THEN b.RVTTI ELSE NULL END) minRVTTI
				, min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND ROUND(b.HVTTI,0) = 0 
					THEN b.Time ELSE NULL END) - WarningStartTime AS HV_CrossRV_Time
				, min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND ROUND(b.RVTTI,0) = 0 
					THEN b.Time ELSE NULL END) - WarningStartTime AS RV_CrossRV_Time
				, min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND ROUND(b.HVTTI,0) = 0 
					THEN b.LatRange ELSE NULL END) AS Range_HV@conflictZone
				, min(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND ROUND(b.RVTTI,0) = 0 
					THEN b.LongRange ELSE NULL END) AS Range_RV@conflictZone
				, SUM(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.RV_Speed < 1.12 THEN 1 ELSE NULL END)/10.0 AS RV_Stopped_s
				, MAX(b.RV_Speed) maxRV_Speed_all
				FROM #FcwTemp3 a
				LEFT JOIN 
				(	SELECT *, RangeDiff =  ABS( Range - LAG(Range) OVER(Partition by eventtype, volpeid order by time) )
					FROM [NYCDB].[dbo].Volpe_NYC_Veh_Event_Kinematics 
				) b
				ON a.HostVehID = b.hostVehicleID AND a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND b.Time BETWEEN a.WarningStartTime - 100 and a.WarningStartTime + 100
				GROUP BY a.EventID, a.VolpeID, a.HostVehID, a.WarningStartTime, a.WarningType, a.Speed
			) a
			LEFT JOIN [NYCDB].[dbo].HostVehicleData b
			ON a.EventID = b.EventID AND b.Time BETWEEN a.WarningStartTime - 100 AND a.WarningStartTime + 100
			GROUP BY a.EventID, a.WarningStartTime, a.Speed, a.meanHVX, a.meanRVX, a.maxRangeDiff,
			minHVSpeed, minRVspeed, minHVTTI, minRVTTI, HV_CrossRV_Time, RV_CrossRV_Time, Range_HV@conflictZone, Range_RV@conflictZone, RV_Stopped_s, maxRV_Speed_all
		) a
	) b
	ON a.EventID = b.EventID
) a --where Good_Data = 1 AND UsefulCriteria = 1
ORDER BY a.VolpeID




Select b.LatRange, b.LongRange
from #FcwTemp3 a
LEFT JOIN [NYCDB].[dbo].[Volpe_NYC_Veh_Event_Kinematics] b
ON a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND round(a.WarningStartTime,1) = ROUND(b.Time,1)+.1
WHERE a.RV_Location = 0
order by b.LatRange desc

Select HostVehID
from #FcwTemp3 where RV_OppositeDirection = 1

Select RVLocation, HV_StraightRd, RV_StraightRd, count(*)
from #FcwTemp3
group by RVLocation, HV_StraightRd, RV_StraightRd
order by RVLocation, HV_StraightRd, RV_StraightRd

Select RVLocation, HV_StraightRd, RV_StraightRd, count(*)
from #FcwTemp3 
WHERE RVLocation IN (1,2) AND HV_StraightRd = 1 AND RV_StraightRd = 1 AND ABS(RV_Z) < 4.5
group by RVLocation, HV_StraightRd, RV_StraightRd
order by RVLocation, HV_StraightRd, RV_StraightRd


Select *,
CASE 
	WHEN (meanHVX = 0 or meanRVX = 0) THEN 44 -- data position issue
	WHEN HV_MovingStatus = 'StopRolling' AND RVTTI > 12 THEN 55 
	WHEN ABS(LatRange) < 4.5 THEN 100 -- average car length
	ELSE 1	END UsefulAlert
FROM 
(	Select a.*,
	CASE 
		WHEN RV_CrossRV_Time > HV_CrossRV_Time THEN 'HV-RV'
		WHEN RV_CrossRV_Time < HV_CrossRV_Time THEN 'RV-HV'
		WHEN HV_CrossRV_Time > 0 THEN 'HV-N/A'
		WHEN RV_CrossRV_Time > 0 THEN 'RV-N/A'
		ELSE 'N/A' END FirstConflictZone,
	CASE 
		WHEN RV_CrossRV_Time > HV_CrossRV_Time THEN RV_CrossRV_Time - HV_CrossRV_Time
		WHEN RV_CrossRV_Time < HV_CrossRV_Time THEN HV_CrossRV_Time - RV_CrossRV_Time 
		ELSE NULL END AS PostEncroachment,
	CASE	
		WHEN a.Speed <= 4.47 THEN 'StopRolling'
		WHEN a.Speed > 4.47 THEn 'Moving' ELSE NULL END 'HV_MovingStatus'
	FROM 
	(	Select a.HostVehID, a.VolpeID, a.WarningType, a.WarningStartTime, a.RV_Z, a.Speed, a.RVTTI, a.RV_OppositeDirection, a.LatRange,
		min(b.HV_Speed) minHVSpeed, min(b.RV_Speed) minRVspeed,
		min(b.HVTTI) minHVTTI, Min(b.RVTTI) minRVTTI,
		min(CASE WHEN ROUND(b.HVTTI,0) = 0 then b.time else null end) - WarningStartTime AS HV_CrossRV_Time,
		min(CASE WHEN ROUND(b.RVTTI,0) = 0 then b.time else null end) - WarningStartTime AS RV_CrossRV_Time,
		min(CASE WHEN ROUND(b.HVTTI,0) = 0 then b.LatRange else null end) AS Range_HV@conflictZone,
		min(CASE WHEN ROUND(b.RVTTI,0) = 0 then b.LongRange else null end) AS Range_RV@conflictZone
		,CASE WHEN max(c.Yaw*0.01745) > 0.3 THEN 1 ELSE 0 END HV_TurnRightAfterWarn
		,min(CASE WHEN c.Speed > 2.24 AND abs(c.Yaw) > 0 THEN 1/(c.Yaw*0.01745/c.Speed) else null end) minR
		,max(CASE WHEN c.Speed > 2.24 AND abs(c.Yaw) > 0 THEN 1/(c.Yaw*0.01745/c.Speed) else null end) maxR

		,AVG(b.HVX) meanHVX, AVG(b.RVX) meanRVX
		from #FcwTemp3 a
		LEFT JOIN [NYCDB].[dbo].[Volpe_NYC_Veh_Event_Kinematics] b
		ON a.VolpeID = b.VolpeID AND a.WarningType = b.EventType AND b.Time BETWEEN a.WarningStartTime and a.WarningStartTime+10
		--LEFT JOIN [NYCDB].[dbo].[HostVehicleData] c
		--ON a.VolpeID = c.VolpeID AND a.WarningType = c.EventType AND c.Time BETWEEN a.WarningStartTime and a.WarningStartTime+10
		WHERE RVLocation IN (1,2) AND a.HV_StraightRd = 1 AND a.RV_StraightRd = 1 AND ABS(a.RV_Z) < 4.5
		GROUP BY a.HostVehID, a.VolpeID, a.WarningType, a.WarningStartTime, a.RV_Z, a.Speed, a.RVTTI, a.RV_OppositeDirection, a.LatRange
	) a
) a 
