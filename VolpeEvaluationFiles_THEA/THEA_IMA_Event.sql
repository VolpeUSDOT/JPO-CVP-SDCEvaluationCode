Select RV_Location, count(*)
FROM
(
SELECT 
CASE 
	WHEN HV_onCollisionPath > 0 THEN '1-inpath'
	WHEN HV_onCollisionPath = 0 AND Comment like '%elevation%' THEN '2-over/under path'
	WHEN HV_onCollisionPath = 0 AND Comment like '%behind%' THEN '3-following from behind'
	WHEN Comment like '%bsm%' THEN '4-no bsm'
	ELSE '5-Other' END RV_Location
  FROM [THEADB_V2].[dbo].[LoggerEventToSDC] WHERE WarningType = 'IMA'

  ) a
  Group by RV_Location


SELECT a.*, -- intial condition
--5 seconds after alert started
b.meanAx, b.PeakAx, b.BrakeResponseTime, b.minHV_TTI,
c.HV_TTI AS BrakeOnsetHV_TTI,
d.HV_TTI AS BrakeReleaseHV_TTI
iNTO #IMATemp3
FROM
(
	SELECT a.EventID, a.HostVehID, a.HV_ID, a.StartTime, b.ParticipantCategory, PreCrashScenario, 
	CASE 
		WHEN b.ParticipantCategory = 'All-Silent' THEN 0
		WHEN b.ParticipantCategory = 'All-Active' THEN 1
		WHEN b.ParticipantCategory = 'Silent-Active' AND a.StartTime BETWEEN b.FirstSilent AND b.LastSilent THEN 0
		ELSE 1 END IsActive,
	a.WarningType, a.Speed, a.Ax, 
	CASE WHEN Brake = 1 THEN 1 ELSE Brake END Brake,
	LongRange, LatRange, HV_TTI, 
	RV_TTI, RV_Speed, RV_Ax,
	CASE WHEN RV_Brake = 1 THEN 1 ELSE RV_Brake END RV_Brake
	FROM
	(
		SELECT 
		d.HV_ID, d.StartTime,d.EventID, d.HostVehID, d.PreCrashScenario,
		a.Time, a.WarningType, a.Speed, a.Ax, a.Brake,
		b.Speed RV_Speed, b.Ax RV_Ax, b.Brake RV_Brake,
		c.LongRange, c.LatRange, c.HVTTI AS HV_TTI, c.RVTTI AS RV_TTI
		FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventData a
		LEFT JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventData b
		ON a.WarningType = b.WarningType AND a.eventID = b.eventID and a.Time = b.time 
		LEFT JOIN THEADB_V2.dbo.Volpe_THEA_Veh_Event_Kinematics c
		ON b.WarningType = c.warningType AND b.eventID = c.eventID AND b.time = c.Time
		INNER JOIN 
		(	SELECT a.HostVehID, a.HV_ID, a.StartTime, cast(a.StartTime as datetime2(1)) AlertStartTime, b.* 
			FROM THEADB_V2.dbo.Volpe_Thea_All_Warning_07312020 a
			INNER JOIN THEADB_V2.dbo.LoggerEventToSDC b
			ON a.WarningType = b.WarningType AND  a.EventID = b.EventID
			WHERE a.WarningType = 'IMA' 
		) d
		ON a.WarningType = d.WarningType AND  a.EventID = d.EventID AND a.Time = d.AlertStartTime
		WHERE a.WarningType = 'IMA' AND d.HV_onCollisionPath > 0 -- on collsion path
	) a
	LEFT JOIN [THEADB_V2].[dbo].[Volpe_Thea_VehicleParticipantCategories] b
	ON a.HostVehID = b.vehicleID
) a
--order by a.eventID, a.Time
LEFT JOIN
(	-- 5 second-window after alert started
	SELECT a.EventID, a.HostVehID, a.StartTime, a.warningType,
	AVG(CASE WHEN a.Ax < 0 THEN Ax ELSE NULL END) meanAx,
	MIN(CASE WHEN a.Ax < 0 THEN Ax ELSE NULL END) peakAx,
	MIN(CASE WHEN a.Brake = 1 THEN a.Time ELSE NULL END) BrakeStartTime,
	Max(CASE WHEN a.Brake = 1 THEN a.Time ELSE NULL END) BrakeEndTime,
	DATEDIFF(ms, min(AlertStartTime), MIN(CASE WHEN a.Brake = 1 THEN a.Time ELSE NULL END))/1000.0 AS BrakeResponseTime,
	MIN(HV_TTI) minHV_TTI
	FROM
	(
		SELECT 
		d.HV_ID, d.StartTime, d.AlertStartTime, d.EventID, d.HostVehID, 
		a.Time, a.warningType, a.Speed, a.Ax, a.Brake,
		b.Speed RV_Speed, b.Ax RV_Ax, b.Brake RV_Brake,
		c.LongRange, c.LatRange, c.HVTTI AS HV_TTI, c.RVTTI AS RV_TTI
		FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventData a
		LEFT JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventData b
		ON a.WarningType = b.WarningType AND a.eventID = b.eventID and a.Time = b.time 
		LEFT JOIN THEADB_V2.dbo.Volpe_THEA_Veh_Event_Kinematics c
		ON b.WarningType = c.WarningType AND  b.eventID = c.eventID AND b.time = c.Time
		INNER JOIN 
		(	SELECT a.HostVehID, a.HV_ID, a.StartTime, cast(a.StartTime as datetime2(1)) AlertStartTime, b.* 
			FROM THEADB_V2.dbo.Volpe_Thea_All_Warning_07312020 a
			INNER JOIN THEADB_V2.dbo.LoggerEventToSDC b
			ON a.WarningType = b.WarningType AND a.EventID = b.EventID
			WHERE a.WarningType = 'IMA'
		) d
		ON a.WarningType = b.WarningType AND a.eventID = d.EventID AND a.Time BETWEEN d.AlertStartTime AND DATEADD(s,5,d.AlertStartTime)
		WHERE a.WarningType = 'IMA' AND d.HV_onCollisionPath IN(1,2) -- on collsion path
	) a
	GROUP BY a.EventID, a.HostVehID, a.StartTime, a.warningType
) b
ON a.WarningType = b.WarningType AND a.eventID = b.eventID
LEFT JOIN 
(	SELECT 
	a.EventID, a.hostVehicleID, a.Time, a.warningType, a.Speed, a.Ax, a.Brake,
	b.Speed RV_Speed, b.Ax RV_Ax, b.Brake RV_Brake,
	c.LongRange, c.LatRange, c.HVTTI AS HV_TTI, c.RVTTI AS RV_TTI
	FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventData a
	LEFT JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventData b
	ON a.WarningType = b.WarningType AND a.eventID = b.eventID and a.Time = b.time 
	LEFT JOIN THEADB_V2.dbo.Volpe_THEA_Veh_Event_Kinematics c
	ON b.WarningType = c.WarningType AND b.eventID = c.eventID AND b.time = c.Time
	WHERE a.WarningType = 'IMA'
) c
ON b.WarningType = c.WarningType AND b.eventID = c.eventID AND b.BrakeStartTime = c.Time
LEFT JOIN 
(	SELECT 
	a.EventID, a.hostVehicleID, a.Time, a.warningType, a.Speed, a.Ax, a.Brake,
	b.Speed RV_Speed, b.Ax RV_Ax, b.Brake RV_Brake,
	c.LongRange, c.LatRange, c.HVTTI AS HV_TTI, c.RVTTI AS RV_TTI
	FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventData a
	LEFT JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventData b
	ON a.WarningType = b.WarningType AND a.eventID = b.eventID and a.Time = b.time 
	LEFT JOIN THEADB_V2.dbo.Volpe_THEA_Veh_Event_Kinematics c
	ON b.WarningType = c.WarningType AND b.eventID = c.eventID AND b.time = c.Time
	WHERE a.WarningType = 'IMA'
) d
ON b.WarningType = d.WarningType AND b.eventID = d.eventID AND b.BrakeEndTime = d.Time
ORDER by a.EventID, a.HostVehID, a.StartTime 

select *--IsActive, count(*)
from #IMATemp3 --where prec
order by PreCrashScenario ASC
group by IsActive

Select PreCrashScenario, count(*), count(distinct HostVehID)
From #IMATemp3 WHERE PreCrashScenario <6
group by PreCrashScenario
