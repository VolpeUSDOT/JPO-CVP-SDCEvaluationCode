Select RV_Location, count(*)
FROM
(
	SELECT 
	CASE 
		WHEN HV_onCollisionPath > 0 AND RV_RelativeLocation = 1  THEN '1-inpath'
		WHEN HV_onCollisionPath = 0 AND RV_RelativeLocation = 2  THEN '2-Adjacent Lane(s)'
		WHEN HV_onCollisionPath = 0 AND RV_RelativeLocation = 1  THEN '3-Turnoff/LC RV'
		WHEN RV_RelativeLocation = 3 AND Comment like '%behind%' THEN '4-following from behind'
		WHEN RV_RelativeLocation = 3 AND Comment like '%underpass%' THEN '5-over/underpass'
		WHEN Comment like '%bsm%' THEN '6-no bsm'
		ELSE '7-Other' END RV_Location, PreCrashScenario
	  FROM [THEADB_V2].[dbo].[LoggerEventToSDC] WHERE WarningType = 'FCW'
) a Where PreCrashScenario = 2
  Group by RV_Location

SELECT 
--intial condition
a.*,
--5 seconds window after alert started
b.RV_Stopped_sec, b.meanAx, b.PeakAx, 
CASE WHEN b.BrakeResponseTime <= 0.05 THEN 0 ELSE b.BrakeResponseTime END BrakeResponseTime, -- TimeDiff near 0 is 0 due time values betweeen tables are not match one to one.
b.minTTC, b.minHeadway,
--BrakeOnset
c.TTC AS BrakeOnsetTTC, c.Range AS BrakeOnsetRange, c.Range/c.Speed AS BrakeOnsetHeaday
INTO #FcwTemp2
FROM
(
	SELECT a.EventID, a.HostVehID, a.HV_ID, a.StartTime, b.ParticipantCategory, a.PreCrashScenario,
	CASE 
		WHEN b.ParticipantCategory = 'All-Silent' THEN 0
		WHEN b.ParticipantCategory = 'All-Active' THEN 1
		WHEN b.ParticipantCategory = 'unknown_category' THEN 3
		WHEN b.ParticipantCategory = 'Silent-Active' AND a.StartTime BETWEEN b.FirstSilent AND b.LastSilent THEN 0
		ELSE 1 END IsActive,
	a.WarningType, a.Speed, a.Brake , a.Range, Rdot AS RangeRate, 
	CASE WHEN Rdot < 0 THEN -a.Range/Rdot ELSE NULL END TTC,
	a.Ax,
	RV_Speed, RV_Ax,
	CASE WHEN RV_Brake = 1 THEN 1 ELSE RV_Brake END RV_Brake, 
	CASE
		WHEN RV_Speed <= 1.12 THEN 'LVS'
		WHEN RV_Brake = 1 OR RV_Ax <=-0.49 THEN 'LVD' 
		WHEN RV_Brake = 1 OR RV_Ax > 0.49 THEN 'LVA'
		ELSE 'LVM' END LeadVehState,
	a.Range/a.Speed AS Headway
	FROM
	(
		SELECT 
		d.HV_ID, d.StartTime,a.EventID, d.HostVehID, a.Time, a.WarningType, d.PreCrashScenario, a.Speed, a.Ax, a.Brake,
		b.Speed RV_Speed, b.Ax RV_Ax, b.Brake RV_Brake,
		c.Range, (b.Speed-a.Speed) AS Rdot
		FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventData a
		LEFT JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventData b
		ON a.WarningType = b.WarningType AND a.eventID = b.eventID and a.Time = b.time 
		LEFT JOIN THEADB_V2.dbo.Volpe_THEA_Veh_Event_Kinematics c
		ON b.WarningType = c.WarningType AND b.eventID = c.eventID AND b.time = c.Time
		INNER JOIN 
		(	SELECT a.HostVehID, a.HV_ID, a.StartTime, cast(a.StartTime as datetime2(1)) AlertStartTime, b.* 
			FROM THEADB_V2.dbo.Volpe_Thea_All_Warning_07312020 a
			INNER JOIN THEADB_V2.dbo.LoggerEventToSDC b
			ON a.WarningType = b.WarningType AND a.EventID = b.EventID
			WHERE a.WarningType = 'FCW'
		) d
		ON a.WarningType = d.WarningType AND a.eventID = d.EventID AND a.Time = d.AlertStartTime
		WHERE a.WarningType = 'FCW' AND d.RV_RelativeLocation = 1 AND d.HV_onCollisionPath IN(1,2) -- inpath and on collsion path
	) a
	INNER JOIN [THEADB_V2].[dbo].[Volpe_Thea_VehicleParticipantCategories] b
	ON a.HostVehID = b.vehicleID
) a
--order by a.eventID, a.Time
LEFT JOIN
(	-- 5 second-window after alert started
	SELECT a.EventID, a.HostVehID, a.StartTime, a.WarningType,
	AVG(CASE WHEN a.Ax < 0 THEN Ax ELSE NULL END) meanAx,
	MIN(CASE WHEN a.Ax < 0 THEN Ax ELSE NULL END) peakAx,
	MIN(CASE WHEN a.Brake = 1 THEN a.Time ELSE NULL END) BrakeStartTime,
	DATEDIFF(ms, min(StartTime), MIN(CASE WHEN a.Brake = 1 THEN a.Time ELSE NULL END))/1000.0 AS BrakeResponseTime,
	MIN(TTC) minTTC,
	MIN(a.Range/a.Speed) AS minHeadway,
	Count(CASE WHEN RV_Speed < 1.12 THEN a.Time ELSE NULL END)/10.0 RV_Stopped_sec
	FROM
	(
		SELECT 
		d.StartTime,d.EventID, d.HostVehID, a.Time, a.WarningType, a.Speed, a.Ax, a.Brake, -- add minTTC, add TTC at RV 1st brake onset
		b.Speed RV_Speed, b.Ax RV_Ax, b.Brake RV_Brake,
		c.Range, c.RangeRate, (b.Speed-a.Speed) AS Rdot,
		CASE WHEN (b.Speed-a.Speed) < 0 THEN -c.Range/(b.Speed-a.Speed) ELSE NULL END TTC
		FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventData a
		LEFT JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventData b
		ON a.WarningType = b.WarningType AND a.eventID = b.eventID and a.Time = b.time 
		LEFT JOIN THEADB_V2.dbo.Volpe_THEA_Veh_Event_Kinematics c
		ON b.WarningType = c.WarningType AND b.eventID = c.eventID AND b.time = c.Time
		INNER JOIN 
			(	SELECT a.HostVehID, a.StartTime, cast(a.StartTime as datetime2(1)) AlertStartTime, b.* 
				FROM THEADB_V2.dbo.Volpe_Thea_All_Warning_07312020 a
				INNER JOIN THEADB_V2.dbo.LoggerEventToSDC b
				ON a.WarningType = b.WarningType AND a.EventID = b.EventID
				WHERE a.WarningType = 'FCW'
			) d
		ON a.eventID = CAST(d.EventID as int) AND a.Time BETWEEN d.AlertStartTime AND DATEADD(s,5,d.AlertStartTime)
		WHERE a.WarningType = 'FCW' AND d.RV_RelativeLocation = 1 AND d.HV_onCollisionPath IN(1,2) -- inpath and on collsion path
	) a
	GROUP BY a.EventID, a.HostVehID, a.StartTime, a.WarningType
) b
ON a.WarningType = b.WarningType AND a.eventID = b.eventID
LEFT JOIN 
(	SELECT 
	a.EventID, a.hostVehicleID, a.Time, a.WarningType, a.Speed, a.Ax, a.Brake,
	b.Speed RV_Speed, b.Ax RV_Ax, b.Brake RV_Brake,
	c.Range, (b.Speed-a.Speed) AS Rdot,
	CASE WHEN (b.Speed-a.Speed) < 0 THEN -c.Range/(b.Speed-a.Speed) ELSE NULL END TTC
	FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventData a
	LEFT JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventData b
	ON a.WarningType = b.WarningType AND a.eventID = b.eventID and a.Time = b.time 
	LEFT JOIN THEADB_V2.dbo.Volpe_THEA_Veh_Event_Kinematics c
	ON b.WarningType = c.WarningType AND b.eventID = c.eventID AND b.time = c.Time
	WHERE a.WarningType = 'FCW'
) c
ON b.WarningType = c.WarningType AND b.eventID = c.eventID AND b.BrakeStartTime = c.Time
ORDER by a.EventID, a.HostVehID, a.StartTime




