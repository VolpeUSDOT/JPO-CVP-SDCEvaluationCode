INSERT INTO WYDOTDB_V2.dbo.Volpe_Wydot_BsmData
Select a.BsmID AS BsmID, a.VolpeID, a.Time
, a.Speed, a.ALong AS Ax, a.ALat AS Ay, a.AVert AS Az, a.YawRate, a.Latitude, a.Longitude, a.Elevation, a.Heading, a.Length*0.01 AS Length, a.Width*0.01 AS Width
, Range = 111.045*DEGREES(ACOS(COS(RADIANS(a.latitude))*COS(RADIANS(b.Latitude))*COS(RADIANS(a.Longitude)-RADIANS(b.Longitude))+SIN(RADIANS(a.Latitude))*SIN(RADIANS(b.Latitude))))*1000
, (b.Speed - a.Speed) AS RangeRate
, b.Speed AS RV_Speed, b.ALong AS RV_Ax, b.ALat AS RV_Ay, b.AVert AS RV_Az, b.YawRate AS RV_YawRate, b.Latitude AS RV_Latitude
, b.Longitude AS RV_Longitude, b.Elevation AS RV_Elevation, b.Heading AS RV_Heading, b.Length*0.01 AS RV_Length, b.Width*0.01 AS RV_Width
--INTO #TempBsmData
FROM
(	SELECT a.*
	FROM
	(	SELECT *, convert(datetime2(1), DateTime) AS Time
		, DateDiffHV = DateDiff(ms,LAG(DateTime) OVER(Partition by VolpeID ORDER BY VolpeID, Datetime), DateTime)
		FROM  [WYDOTDB_V2].[dbo].[HostVehicleData] --order by VolpeID, Time 
	) a WHERE DateDiffHV !=0
) a
LEFT JOIN 
(	SELECT a.*
	FROM
	(	SELECT *, convert(datetime2(1), DateTime) AS Time
		, DateDiffRV = DateDiff(ms,LAG(DateTime) OVER(Partition by VolpeID ORDER BY VolpeID, Datetime), DateTime)
		FROM  [WYDOTDB_V2].[dbo].[TargetVehicleData]
	) a WHERE DateDiffRV !=0
) b
ON a.VolpeId = b.VolpeID AND a.Time = b.Time
ORDER BY a.VolpeID, a.Time


SELECT a.VolpeID, a.WarningStartTime, a.Speed, b.RV_Speed
, Range = 111.045*DEGREES(ACOS(COS(RADIANS(a.latitude))*COS(RADIANS(b.Latitude))*COS(RADIANS(a.Longitude)-RADIANS(b.Longitude))+SIN(RADIANS(a.Latitude))*SIN(RADIANS(b.Latitude))))*1000
, (b.RV_Speed-a.Speed) RangeRate
, CASE 
	WHEN (b.RV_Speed-a.Speed) < -1.12 THEN 'Closing'
	WHEN (b.RV_Speed-a.Speed) BETWEEN -1.12 AND 1.12 THEN 'Following'
	WHEN (b.RV_Speed-a.Speed) > 1.12 THEN 'Separating'
	ELSE NULL END HV_DrivingState
, CASE WHEN (b.RV_Speed-a.Speed) < 0 THEN 
	-((111.045*DEGREES(ACOS(COS(RADIANS(a.latitude))*COS(RADIANS(b.Latitude))*COS(RADIANS(a.Longitude)-RADIANS(b.Longitude))+SIN(RADIANS(a.Latitude))*SIN(RADIANS(b.Latitude))))*1000) 
		- 0.5*(a.Length + b.RV_Length))/(b.RV_Speed-a.Speed) ELSE NULL END AS TTC
,  CASE WHEN Speed > 0 THEN (111.045*DEGREES(ACOS(COS(RADIANS(a.latitude))*COS(RADIANS(b.Latitude))*COS(RADIANS(a.Longitude)-RADIANS(b.Longitude))+SIN(RADIANS(a.Latitude))*SIN(RADIANS(b.Latitude))))*1000)/Speed ELSE NULL END Headway
INTO #AlertOnset
FROM
(	SELECT a.Volpeid, a.WarningStartTime, CAST(a.HVSpeed as float) AS Speed, b.Time, b.Latitude, b.Longitude, b.Length
	,ROW_NUMBER() OVER(PARTITION BY a.VolpeID ORDER BY a.VolpeID, b.Time) FirstChoice -- no direct match at alert onset time
	FROM 
	(	SELECT convert(datetime2(1), AlertStartTime) AS WarningStartTime,*
		FROM  [WYDOTDB_V2].[dbo].[FCWAlerts] 
	) a
	LEFT JOIN WYDOTDB_V2.dbo.Volpe_Wydot_BsmData b
	ON a.VolpeID = b.VolpeID AND b.Time BETWEEN WarningStartTime AND DATEADD(ms,100,WarningStartTime)
) a 
LEFT JOIN
(	SELECT a.Volpeid, a.WarningStartTime, b.Speed AS RV_Speed, b.DateTime, b.Latitude, b.Longitude, b.Length*0.01 AS RV_Length
	,ROW_NUMBER() OVER(PARTITION BY a.VolpeID ORDER BY a.VolpeID, b.DateTime) RV_FirstChoice -- no direct match at alert onset time
	FROM 
	(	SELECT convert(datetime2(1), AlertStartTime) AS WarningStartTime,*
		FROM  [WYDOTDB_V2].[dbo].[FCWAlerts] 
	) a
	LEFT JOIN WYDOTDB_V2.dbo.TargetVehicleData b
	ON a.VolpeID = b.VolpeID AND b.DateTime BETWEEN DATEADD(ms,-300,WarningStartTime) AND DATEADD(ms,200,WarningStartTime)
) b
ON a.VolpeID = b.VolpeID
WHERE a.FirstChoice = 1 AND b.RV_FirstChoice = 1
order by a.VolpeID


SElect a.*
,AVG(CASE WHEN b.Ax < 0 THEN b.Ax ELSE NULL END) meanAx
,MIN(CASE WHEN b.Ax < 0 THEN b.Ax ELSE NULL END) peakAx
INTO #FinalSet
FROm
(	SELECT a.VolpeID, a.WarningStartTime, a.Speed, a.RV_Speed, a.Range, a.RangeRate, a.HV_DrivingState, a.TTC, a.Headway,
	a.ResolvedClosingConflictTime_s, a.SpeedRedClosingResponseTime_s, a.ResolvedFollowingConflictTime_s, a.SpeedRedFollowingResponseTime_s, minSpeed
	,MIN(CASE WHEN a.minSpeed = b.Speed THEN b.Time ELSE NULL END) minSpeed_Time
	,MIN(TTC_s) AS minTTC_s
	,MIN(Headway_s) AS minHeadway_s
	FROM
	(	Select a.VolpeID, a.WarningStartTime, a.Speed, a.RV_Speed, a.Range, a.RangeRate, a.HV_DrivingState, a.TTC, a.Headway
		--Closing
		, DateDiff(ms, WarningStartTime, MIN(CASE WHEN HV_DrivingState = 'Closing' AND b.RangeRate > 0 THEN b.Time ELSE NULL END))/1000.0 ResolvedClosingConflictTime_s
		, DateDiff(ms, WarningStartTime, MIN(CASE WHEN HV_DrivingState = 'Closing' AND (a.Speed-b.Speed) > 1.12 THEN b.Time ELSE NULL END))/1000.0 SpeedRedClosingResponseTime_s
		, MIN(b.Speed) minSpeed
		--Following
		, DateDiff(ms, WarningStartTime, MIN(CASE WHEN HV_DrivingState = 'Following' AND b.RangeRate > 2.24 THEN b.Time ELSE NULL END))/1000.0 ResolvedFollowingConflictTime_s
		, DateDiff(ms, WarningStartTime, MIN(CASE WHEN HV_DrivingState = 'Following' AND (a.Speed-b.Speed) > 1.12 THEN b.Time ELSE NULL END))/1000.0 SpeedRedFollowingResponseTime_s
		,count(*) DataCount
		FROM #AlertOnset a
		LEFT JOIN WYDOTDB_V2.dbo.Volpe_Wydot_BsmData b
		ON a.VolpeID = b.VolpeID AND b.Time BETWEEN a.WarningStartTime AND DATEADD(s,10,WarningStartTime)
		GROUP BY a.VolpeID, a.WarningStartTime, a.Speed, a.RV_Speed, a.Range, a.RangeRate, a.HV_DrivingState, a.TTC, a.Headway
	) a
	LEFT JOIN 
	(	SELECT *
		, CASE WHEN (RV_Speed - Speed) < 0 AND (Range - 0.5*(Length + RV_Length)) > 0 THEN -(Range - 0.5*(Length + RV_Length))/(RV_Speed - Speed) ELSE NULL END TTC_s
		, CASE WHEN Speed > 0 AND (Range - 0.5*(Length + RV_Length)) > 0 THEN (Range - 0.5*(Length + RV_Length))/Speed ELSE NULL END Headway_s
		FROM WYDOTDB_V2.dbo.Volpe_Wydot_BsmData 
	) b
	ON a.VolpeID = b.VolpeID AND b.Time BETWEEN a.WarningStartTime AND DATEADD(s,10,WarningStartTime)
	GROUP BY a.VolpeID, a.WarningStartTime, a.Speed, a.RV_Speed, a.Range, a.RangeRate, a.HV_DrivingState, a.TTC, a.Headway,
	a.ResolvedClosingConflictTime_s, a.SpeedRedClosingResponseTime_s, a.ResolvedFollowingConflictTime_s, a.SpeedRedFollowingResponseTime_s, minSpeed
) a
LEFT JOIN WYDOTDB_V2.dbo.Volpe_Wydot_BsmData b
ON a.VolpeID = b.VolpeID AND b.Time BETWEEN a.WarningStartTime AND a.minSpeed_Time
GROUP BY a.VolpeID, a.WarningStartTime, a.Speed, a.RV_Speed, a.Range, a.RangeRate, a.HV_DrivingState, a.TTC, a.Headway,
	a.ResolvedClosingConflictTime_s, a.SpeedRedClosingResponseTime_s, a.ResolvedFollowingConflictTime_s, a.SpeedRedFollowingResponseTime_s, minSpeed, minSpeed_Time, minTTC_s, minHeadway_s
ORDER BY a.VolpeID


INSERT INTO  WYDOTDB_V2.[dbo].[Volpe_DA_FCW2]
SELECT
CASE 
	WHEN b.HV_DataCount = 0 OR b.RV_DataCount = 0 THEN 'NoHV/RVbsm' 
	WHEN a.Speed < 2.24 THEN 'SpeedAlertOnsetBelow 5mph'
	WHEN a.HV_DrivingState IS NULL THEN 'NoRVData_Within0.5s@AlertOnset'
	WHEN a.HV_DrivingState = 'Closing' THEN 'Closing'
	WHEN a.HV_DrivingState = 'Following' THEN 'Following'
	WHEN a.HV_DrivingState = 'Separating' THEN 'Separating'
ELSE NULL END UsefulAlert, a.*
FROM #FinalSet a
LEFT JOIN 
(	Select a.*, b.RV_DataCount
	FROM
	(	SELECT a.VolpeID, a.AlertStartTime, count(b.DateTime) HV_DataCount
		FROM [WYDOTDB_V2].[dbo].FCWAlerts a
		LEFT JOIN [WYDOTDB_V2].[dbo].[HostVehicleData] b
		ON a.VolpeID = b.VolpeID AND b.DateTime BETWEEN DATEADD(s,-100,a.AlertStartTime) AND DATEADD(s,100,a.AlertStartTime)
		group by a.VolpeID, a.AlertStartTime
	) a
	LEFT JOIN 
	(	SELECT a.VolpeID, a.AlertStartTime, count(b.DateTime) RV_DataCount
		FROM [WYDOTDB_V2].[dbo].FCWAlerts a
		LEFT JOIN [WYDOTDB_V2].[dbo].[TargetVehicleData] b
		ON a.VolpeID = b.VolpeID AND b.DateTime BETWEEN DATEADD(s,-100,a.AlertStartTime) AND DATEADD(s,100,a.AlertStartTime)
		group by a.VolpeID, a.AlertStartTime
	) b ON a.VolpeID = b.VolpeID
) b 
ON a.VolpeID = b.VolpeID
ORDER BY a.VolpeID, a.WarningStartTime