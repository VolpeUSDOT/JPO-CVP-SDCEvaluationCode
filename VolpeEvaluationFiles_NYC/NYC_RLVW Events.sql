--INSERT INTO ---updated on 02/22/2022
--NYCDB.dbo.VolpeDA_RLVW2

SELECT a.VolpeID ,a.EventID, a.WarningStartTime, b.WarningType, a.IntersectionID, a.SignalState,--, a.LaneID
b.Control, b.Active, b.VehClass, b.TimeBin, b.WeatherCond, b.Speed, a.LongRange, b.Ax, b.Brake, 
CASE WHEN b.Speed > 0 AND a.LongRange > 0 THEN a.LongRange/b.Speed ELSE NULL END AS TTI, b.DummyTime
--After alert
,BrakeReactTime_s,meanSpeed,minSpeed,maxSpeed, meanAx, PeakAx, GreenAlertTime_s, EnterIntStartTime
, CASE 
	WHEN a.minSpeed <= 1.12 OR minLongRange >= -0.75*HV_Length THEN 'Not Enter'	--HV stopped before or not enter an intersection
	WHEN a.minSpeed > 1.12 AND a.minLongRange < -0.75*HV_Length AND EnterIntLatRange BETWEEN -3.0 AND 3.0 THEN 
		CASE
			WHEN EnterIntSignalState LIKE '%Remain%' THEN 'Red'--Red light
			WHEN EnterIntSignalState like '%Proceed%' THEN 'FlashingRed' --flashing red light (stop sign)
			WHEN EnterIntSignalState like '%clearance%' THEN 'Yellow' --yellow light				
			WHEN EnterIntSignalState LIKE '%Allowed%' THEN 'Green'--green light
			WHEN EnterIntSignalState like '%dark%' THEN 'LightOff' --light off
			ELSE 'Unknown' --unknown
		END
	ELSE NULL END EnterIntersectionSignalState--, HV_Length	
, EnterIntSpeed
, EnterIntLatRange
, CASE WHEN a.minSpeed > 1.12 AND a.minLongRange < -0.75*HV_Length AND EnterIntLatRange BETWEEN -3.0 AND 3.0
	AND a.GoodData = 1 AND b.Speed BETWEEN 1.12 AND 24.587 AND EnterIntSignalState LIKE '%Remain%' THEN  EnterIntStartTime - RedStartTime ELSE NULL END AS TimeAfterRedLight
--,CASE WHEN (minSpeedTime - a.WarningStartTime)!=0 THEN (minSpeed-Speed)/(minSpeedTime - a.WarningStartTime) ELSE NULL END AS minSpeed_Ax
, CASE WHEN a.GoodData = 1 AND b.Speed BETWEEN 1.12 AND 24.587 THEN 1 ELSE 0 END UsefulEvent 
,  a.DataCountBefore_s, a.DataCountAfter_s, a.maxSpeed_all, a.maxLongRange, a.minLongRange, a.meanHVX, a.meanHVY -- data use for 'GoodData'
,  CASE 
		WHEN DataCountBefore_s > 7.1 OR DataCountAfter_s > 10.1 THEN 'RecordedIssue'
		WHEN maxSpeed_all > 24.5872 THEN 'SpeedAbove55mph'
		WHEN Speed < 1.12 THEN 'SpeedBelow2.5mph' 
		WHEN meanHVX = 0 OR meanHVY = 0 THEN 'VehStationaryXY'
		WHEN LongRange < maxLongRange THEN 'Range<RangeAfterAlert'
		WHEN LongRange < 0 THEN 'HV_EnteredIntersection'
		WHEN LongRange > 160 THEN 'Range>260meters'
		wHEN LongRange is NULL THEN 'RangeNotAvailable'
	ELSE NULL END NonUsefulFilter
FROM
(	SELECT a.eventID, a.VolpeID, a.WarningStartTime, a.IntersectionID, a.SignalState, a.LongRange, --, a.LaneID
	a.DataCountAfter_s, a.DataCountBefore_s, a.maxSpeed_all, BrakeReactTime_s, meanAx, PeakAx, RedStartTime,
	a.WarningEndTime, a.maxLongRange, a.minLongRange, EnterIntStartTime, a.meanSpeed, a.minSpeed, a.maxSpeed, a.meanHVX, a.meanHVY
	, SUM(CASE WHEN a.SignalState LIKE '%Allowed%' AND b.LongRange >= 0 AND b.SignalState LIKE '%Allowed%' THEN 1 ELSE NULL END)/10.0 AS GreenAlertTime_s
	, MIN(CASE WHEN a.VolpeID = b.VolpeID AND ROUND(a.EnterIntStartTime,1) = ROUND(b.Time,1) THEN b.SignalState ELSE NULL END) AS EnterIntSignalState
	, MIN(CASE WHEN a.VolpeID = b.VolpeID AND ROUND(a.EnterIntStartTime,1) = ROUND(b.Time,1) THEN b.HV_Speed ELSE NULL END) AS EnterIntSpeed
	, MIN(CASE WHEN a.VolpeID = b.VolpeID AND ROUND(a.EnterIntStartTime,1) = ROUND(b.Time,1) THEN b.LatRange ELSE NULL END) AS EnterIntLatRange
	--, MIN(CASE WHEN a.VolpeID = b.VolpeID AND a.minSpeed > 1.12 AND ROUND(a.VioStartTime,1) = ROUND(b.Time,1) THEN b.Time ELSE NULL END) VioSignalStatetime
	--, count(CASE WHEN a.VolpeID = b.VolpeID AND a.minSpeed > 1.12 AND ROUND(a.VioStartTime,1) = ROUND(b.Time,1) THEN b.SignalState ELSE NULL END) VioSignalcount
	, CASE 
		WHEN DataCountBefore_s <= 7.1 AND DataCountAfter_s <= 10.1 AND maxSpeed_all <= 24.5872 AND (meanHVX != 0 OR meanHVY != 0)
		AND a.LongRange BETWEEN 0 AND 160 AND a.LongRange >= maxLongRange THEN 1 ELSE 0 END GoodData
	--, MIN(CASE WHEN a.VolpeID = b.VolpeID AND a.minSpeed = b.HV_Speed THEN b.Time ELSE NULL END) minSpeedTime
	FROM
	(	SELECT a.eventID, a.VolpeID, a.WarningStartTime, a.IntersectionID, a.SignalState, a.LongRange, --, a.LaneID
		a.DataCountAfter_s, a.DataCountBefore_s, a.maxSpeed_all, BrakeReactTime_s, meanAx, PeakAx
		--Red light Starttime
		, MIN(CASE WHEN b.SignalState LIKE '%Remain%' THEN b.Time ELSE NULL END) RedStartTime	
		--After Alert
		, MAX(Time) WarningEndTime
		, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 AND b.LongRange BETWEEN -160 AND 160 THEN b.LongRange ELSE NULL END) maxLongRange
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 AND b.LongRange BETWEEN -160 AND 160 THEN b.LongRange ELSE NULL END) minLongRange
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 AND b.LongRange < 0 AND b.LongRange > -160 THEN b.Time ELSE NULL END) EnterIntStartTime
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 AND b.LongRange >= 0 THEN b.HV_Speed ELSE NULL END) meanSpeed
		, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 AND b.LongRange >= 0 THEN b.HV_Speed ELSE NULL END) minSpeed
		, MAX(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 AND b.LongRange >= 0 THEN b.HV_Speed ELSE NULL END) maxSpeed
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 THEN b.HVX ELSE NULL END) meanHVX
		, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime+10 THEN b.HVY ELSE NULL END) meanHVY
		FROM
		(	SELECT a.eventID, a.VolpeID, a.WarningStartTime, a.IntersectionID, a.SignalState, a.LongRange --, a.LaneID
			--All before and after data
			,MIN(b.Time) minTime, MAX(b.Time) maxTime, MAX(Speed) maxSpeed_all
			,SUM(CASE WHEN b.time < a.WarningStartTime THEN 1 else 0 end)/10.0 AS DataCountBefore_s
			,SUM(CASE WHEN b.time > a.WarningStartTime THEN 1 else 0 end)/10.0 AS DataCountAfter_s
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Brake = '78' OR b.Brake = '88' THEN b.Time ELSE NULL END) - a.WarningStartTime AS BrakeReactTime_s
			, AVG(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Along < 0 THEN b.Along ELSE NULL END) meanAx
			, MIN(CASE WHEN b.Time BETWEEN a.WarningStartTime AND a.WarningStartTime + 10 AND b.Along < 0 THEN b.Along ELSE NULL END) PeakAx
			FROM 
			(	SELECT a.eventID, a.VolpeID, a.WarningStartTime
				, b.IntersectionID, b.SignalState, b.LongRange --, b.LaneID
				--, b.Distance, b.Range
				--, CASE WHEN LongRange BETWEEN 0 AND 160 THEN LongRange ELSE Distance END NewRange
				FROM NYCDB.dbo.AllWarningEvent a
				LEFT JOIN NYCDB.dbo.Volpe_NYC_Veh_Event_RLVW_Kinematics_1 b
				ON a.VolpeID = b.VolpeID AND a.WarningType = b.eventType AND round(a.WarningStartTime,1) = ROUND(b.Time,1)
				WHERE a.WarningType = 'RLVW' AND TimeBin NOT like '2020%' AND ((grpid = 20 and active = 0) OR Grpid > 20) --Remove 2020, control-active, and test events
				--ORDER BY b.LongRange
			) a
			LEFT JOIN [NYCDB].[dbo].[HostVehicleData] b
			ON a.EventID = b.EventID AND b.Time BETWEEN a.WarningStartTime - 100 AND a.WarningStartTime + 100  --- timeb4 and/or after may not be samiliar pattern
			GROUP BY a.eventID, a.VolpeID, a.WarningStartTime, a.IntersectionID, a.SignalState, a.LongRange --, a.LaneID
		) a
		LEFT JOIN NYCDB.dbo.Volpe_NYC_Veh_Event_RLVW_Kinematics_1 b
		On a.VolpeID = b.VolpeID AND a.IntersectionID = b.IntersectionID AND b.Time BETWEEN a.WarningStartTime-100 AND a.WarningStartTime+100 --AND a.LaneID = b.LaneID
		--WHERE b.LongRange BETWEEN -160 AND 160
		GROUP BY a.eventID, a.VolpeID, a.WarningStartTime, a.IntersectionID, a.SignalState, a.LongRange, 
		DataCountAfter_s, DataCountBefore_s, maxSpeed_all,BrakeReactTime_s,meanAx,PeakAx --, a.LaneID
	) a
	LEFT JOIN NYCDB.dbo.Volpe_NYC_Veh_Event_RLVW_Kinematics_1 b
	ON a.VolpeID = b.VolpeID AND a.IntersectionID = b.IntersectionID AND b.Time BETWEEN a.WarningStartTime AND a.WarningEndTime
	GROUP BY a.eventID, a.VolpeID, a.WarningStartTime, a.IntersectionID, a.SignalState, a.LongRange, --, a.LaneID
	a.DataCountAfter_s, a.DataCountBefore_s, a.maxSpeed_all, BrakeReactTime_s, meanAx,PeakAx, RedStartTime,
	a.WarningEndTime, a.maxLongRange, a.minLongRange, EnterIntStartTime, a.meanSpeed, a.minSpeed, a.maxSpeed,meanHVX, meanHVY
) a	
LEFT JOIN 
(	SELECT a.*, b.Speed, b.Along AS Ax, b.class AS VehClass, CAST(b.Length as int)*0.01 HV_Length
	, CASE WHEN b.Brake = '78' OR b.Brake = '88' THEN 1 ELSE 0 END Brake
	, CASE WHEN GrpID = 20 THEN 1 ELSE 0 END 'Control'
	FROM NYCDB.dbo.AllWarningEvent a
	LEFT JOIN NYCDB.dbo.HostVehicleData b
	ON a.VolpeID = b.VolpeID AND a.WarningType = b.eventType AND round(a.WarningStartTime,1) = ROUND(b.Time,1)
) b
ON a.EventID = b.EventID AND a.WarningStartTime = b.WarningStartTime
Order by UsefulEvent desc, EnterIntersectionSignalState

