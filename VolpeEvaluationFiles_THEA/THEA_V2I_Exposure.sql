Select HostVehID, 
SUM(CASE WHEN ApplicationType = 'PCW' THEN 1 ELSE NULL END) 'PcwCrosswalk',
SUM(CASE WHEN ApplicationType = 'ERDW' THEN 1 ELSE NULL END) 'ErdwRamp',
SUM(CASE WHEN ApplicationType = 'WWE' THEN 1 ELSE NULL END) 'WweIntersection'
,SUM(CASE WHEN ApplicationType = 'RELout' THEN 1 ELSE NULL END) 'RELout'
,SUM(CASE WHEN (ApplicationType = 'PCW' AND Weekday NOT IN ('Saturday', 'Sunday') AND LocalTime BETWEEN '06:00:00:00' AND '12:00:00:00') THEN 1 ELSE NULL END) 'Weekday_Pcw_06-12am'
,SUM(CASE WHEN (ApplicationType = 'PCW' AND Weekday NOT IN ('Saturday', 'Sunday') AND LocalTime BETWEEN '12:00:00:00' AND '18:00:00:00') THEN 1 ELSE NULL END) 'Weekday_Pcw_12-18pm'
INTO #V2I_Exposure
FROM
(
	Select a.*,
	CAST(CASE 
		WHEN Time BETWEEN '2018-11-04' AND '2019-03-09 23:59:59.999' THEN DATEADD(HOUR,-5,Time)
		WHEN Time BETWEEN '2019-03-10' AND '2019-11-02 23:59:59.999' THEN DATEADD(HOUR,-4,Time)
		WHEN Time BETWEEN '2019-11-03' AND '2020-03-07 23:59:59.999' THEN DATEADD(HOUR,-5,Time)
		WHEN Time BETWEEN '2020-03-08' AND '2020-07-01' THEN DATEADD(HOUR,-4,Time)
	ELSE NULL END AS Time) AS LocalTime,
	FORMAT(CASE 
		WHEN Time BETWEEN '2018-11-04' AND '2019-03-09 23:59:59.999' THEN DATEADD(HOUR,-5,Time)
		WHEN Time BETWEEN '2019-03-10' AND '2019-11-02 23:59:59.999' THEN DATEADD(HOUR,-4,Time)
		WHEN Time BETWEEN '2019-11-03' AND '2020-03-07 23:59:59.999' THEN DATEADD(HOUR,-5,Time)
		WHEN Time BETWEEN '2020-03-08' AND '2020-07-01' THEN DATEADD(HOUR,-4,Time)
	ELSE NULL END, 'dddd') AS Weekday
	FROM
	(
		Select HostVehID, Time, Longitude, Latidute, dtime, ApplicationType
		From
		(	Select a.HostVehID, a.Time, a.Longitude, a.Latidute, DATEDIFF(s, lag(Time) OVER (partition by HostVehID ORDER BY HostVehID, time), Time) dtime, 'PCW' ApplicationType
			FROM THEADB_V2.dbo.Volpe_Thea_SentBsm a
			WHERE --a.HostVehID = '231882' AND
			(a.Latidute BETWEEN 27.950797 AND 27.950967 AND a.Longitude BETWEEN -82.453688 AND -82.453575) -- PcwCrosswalk
			--( (a.Latidute BETWEEN 27.950797 AND 27.950903 AND a.Longitude BETWEEN -82.453681 AND -82.453575) OR-- AND a.Heading BETWEEN 62 and 72) OR --eastbound crosswalk
			--(a.Latidute BETWEEN 27.950847 AND 27.950967 AND a.Longitude BETWEEN -82.453688 AND -82.453584) )-- AND a.Heading BETWEEN 242 and 252) )	--westbound crosswalk
		) a WHERE dtime is NULL OR dtime > 10.0
		UNION
		Select HostVehID, Time, Longitude, Latidute, dtime, ApplicationType
		From
		(	Select a.HostVehID, a.Time, a.Longitude, a.Latidute, DATEDIFF(s, lag(Time) OVER (partition by HostVehID ORDER BY HostVehID, time), Time) dtime, 'WWE' ApplicationType
			FROM THEADB_V2.dbo.Volpe_Thea_SentBsm a
			WHERE --a.HostVehID = '231882' AND
			(	(a.Latidute BETWEEN 27.952218 AND 27.952284 AND a.Longitude BETWEEN -82.449365 AND -82.449278) --Eastbound E Twiggs St
				OR (a.Latidute BETWEEN 27.952283 AND 27.952338 AND a.Longitude BETWEEN -82.448916 AND -82.448852) --Westbound E Twiggs St
				OR (a.Latidute BETWEEN 27.952049 AND 27.952120 AND a.Longitude BETWEEN -82.449029 AND -82.448916) --Northbound N Meridian Ave
			)
			--order by Time
		) a WHERE dtime is NULL OR dtime > 10.0
		UNION
		Select HostVehID, Time, Longitude, Latidute, dtime, ApplicationType
		From
		(	Select a.HostVehID, a.Time, a.Longitude, a.Latidute, DATEDIFF(s, lag(Time) OVER (partition by HostVehID ORDER BY HostVehID, time), Time) dtime, 'ERDW' ApplicationType
			FROM THEADB_V2.dbo.Volpe_Thea_SentBsm a
			WHERE --a.HostVehID = '231882' AND
			(a.Latidute BETWEEN 27.955508 AND 27.955659 AND a.Longitude BETWEEN -82.446441 AND -82.446168 AND a.Heading BETWEEN 250 and 280)
		) a WHERE dtime is NULL OR dtime > 10.0
		UNION
		Select HostVehID, Time, Longitude, Latidute, dtime, ApplicationType
		From
		(	Select a.HostVehID, a.Time, a.Longitude, a.Latidute, DATEDIFF(s, lag(Time) OVER (partition by HostVehID ORDER BY HostVehID, time), Time) dtime, 'RELout' ApplicationType
			FROM THEADB_V2.dbo.Volpe_Thea_SentBsm a
			WHERE --a.HostVehID = '231882' AND
			(a.Latidute BETWEEN 27.955508 AND 27.955659 AND a.Longitude BETWEEN -82.446441 AND -82.446168 AND a.Heading BETWEEN 70 and 100)
		) a WHERE dtime is NULL OR dtime > 10.0
	) a
) a
GROUP BY HostVehID
ORDER BY HostVehID

