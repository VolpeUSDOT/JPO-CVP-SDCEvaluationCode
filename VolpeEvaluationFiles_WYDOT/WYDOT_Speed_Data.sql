CREATE TABLE WydotDB_V2.dbo.Volpe_Wydot_Speed
(
	SensorID		int not null,
	Date_Time		datetime not null,
	TestPeriod		tinyint not null,
	Headway_s		int null,
	SpeedDiff_mph	float null,
	OverSpeedLimit_mph	Float NULL,
	--EquippedVeh --check back later
	Speed_mph		float null,
	Length			float null,
	Class			tinyint null,
	Lane			tinyint null,
	--Rwis		varchar(50) null,
	VslDeviceID		int null,
	LaneDir			tinyint null,
	StationID		varchar(50) null,
	RoadCondition	tinyint null,
	Visibility		tinyint null,
	RelHumidity		tinyint null,
	SurfaceTemp		tinyint null,
	WindSpeed		tinyint null,
	StormNum		int null,
	PostedSpeed		int null,
	PostedSpeedTime	varchar(50) null,
	SpeedCompliant5	tinyint null,
	SpeedBuffer10	tinyint null,
	DataQuality		varchar(50) null,
	StormCat		tinyint null,
	--Primary key (SensorID, Date_Time)
)
GO

---time in second.
INSERT INTO WydotDB_V2.dbo.Volpe_Wydot_Speed
SELECT
Sensor,
DateTime1, 
TestPeriod = CASE WHEN Date1 < '2019-04-30' THEN 0 ELSE 1 END,
Headway_s = DATEDIFF(ss, Lag(Time1) OVER(Partition by Sensor, Lane, Date1 ORDER BY Sensor, Lane, DateTime1),Time1),
VehSpeedDiff_mph = ROUND(Speed - LAG(Speed) OVER(Partition by Sensor, Lane, Date1 Order By Sensor, Lane, Datetime1),2),
--EquippedVeh --check back later
OverSpeedLimit_mph = CASE WHEN Postedspd > 0 THEN  Speed - Postedspd ELSE NULL END,
--VlsSpeedDiff = Speed - 'need to find VSL'
Speed AS Speed_mph, Length, class, Lane,
--Rwis = REPLACE(rwis,'"',''),
VslDeviceID, -- 1 or 2 are static posted speed sign; else variable posted speed limit ID
lanedir,
StationID = REPLACE(stationid,'"',''),
roadcond, vis, rh, surftemp, wndspd, stormnum, postedspd, 
PostedSpeedTime, --CAST(PostedSpeedTime as datetime2), 
speedcompliant5, speedbuffer10, 
DataQuality1, --CASE WHEN DataQuality1 IN(0,1) THEN DataQuality1 ELSE NULL END DataQuality,
stormcat
FROM 
(	Select
	REPLACE(postedspd_vsltime,'"','') as PostedSpeedTime,
	Cast(date_time as datetime) DateTime1, 
	Cast(date_time as date) Date1, 
	Cast(date_time as time) Time1,
	REPLACE(dataquality,'"','') as DataQuality1,
	CASE WHEN lanedir = 1 THEN wb_vsl ELSE eb_vsl end VslDeviceID, * 
	--from [WYDOTDB_v2].[dbo].[SpeedBefore]
	--WHERE cast(date_time as date) BETWEEN '2019-01-01' AND '2019-04-30'
	from [WYDOTDB_v2].[dbo].[SpeedAfter]
	WHERE cast(date_time as date) BETWEEN '2022-01-01' AND '2022-04-30'
) a
--Where a.Date1 = '2019-01-01' and a.sensor = 1075
ORDER BY Sensor, Lane, DateTime1


Select VslDeviceID, StartTime,
CASE WHEN EndTime IS NOT NULL THEN EndTime ELSE StartTime END EndTime,
PostedSpeedLimit
fROM
(
	Select VslDeviceID, LocalTime, PostedSpeedLimit, Cell_Start StartTime,
	CASE WHEN Cell_End is NULL THEN Lead(Cell_End) OVER(partition by deviceid, PostedSpeedLimit order by deviceid, Time) ELSE Cell_End END EndTime
	--,Cell_end, Lead(Cell_End) OVER(partition by deviceid, speedLimit order by deviceid, Time)
	from
	(
		SELECT a.*,
		Cell_Start = CASE WHEN row_id = 1 THEN LocalTime 
			ELSE CASE WHEN ( row_id - lag(row_id)  over(partition by deviceid order by deviceid, Time) ) <> 1 Then Time 
				ELSE NULL END
			END,
		Cell_End = CASE WHEN ( row_id - lead(row_id)  over(partition by deviceid order by deviceid, Time) ) <> -1 Then Time else null end
		From
		(
			SELECT deviceid AS VslDeviceID, local AS LocalTime, vsl_mph AS PostedSpeedLimit
			,row_id = row_number() over(partition by deviceid, vsl_mph order by deviceid, local)
			FROM [WYDOTDB].[dbo].[wydot_vsl_baseline]
			where deviceid = 2148 --and Cast(local as date) = '2016-12-01'
			--order by deviceid, local
		) a
		--order by deviceid, tIME
	 ) a
	 WHERE (Cell_Start is not null OR Cell_End is not null)
	 --order by DeviceID, Time
) a
WHERE Starttime is not null
 order by DeviceID, Time
 
 