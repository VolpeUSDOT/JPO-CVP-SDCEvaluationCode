SELECT 
	w.* ,
	dbo.TimeToIntersection(w.LongRange, w.HV_Speed) as TTI_LongRange_HV,
	dbo.TimeToIntersection(w.LatRange, w.RV_Speed) as TTI_LatRange_RV
--INTO SafetyPilotTestData_result
FROM (
	SELECT
		v.*,
		dbo.PreciseRelativeLocation(v.HV_Heading, v.RV_Heading, v.RelLongRange, v.RelLatRange, v.HV_Length, v.HV_Width, v.RV_Length, v.RV_Width, v.LongRange, v.LatRange) AS PreciseRelativeLocation,
		dbo.HVTTIBasedOnDtI(v.X, v.Y, v.HV_Speed) AS HVTTI,
		dbo.RVTTIBasedOnDtI(v.EastOffset, v.X, v.NorthOffset, v.Y, v.RV_Speed) AS RVTTI,
		dbo.TimeToPointOfInterest(v.Distance, v.HV_Speed) AS TTPOI
	FROM (
		SELECT
			u.*,
			dbo.RelLatRange(u.LatRange, u.HV_Width / 100.0, u.RV_Width / 100.0) AS RelLatRange,
			dbo.CalculateY(u.HV_Slope, u.X) AS Y
		FROM (
			SELECT
				s.*,
				dbo.LatRange(s.Calc_Range, s.LongRange, s.NorthOffset, s.EastOffset, s.HV_Heading) AS LatRange,
				dbo.RelLongRange(s.LongRange, s.HV_Length / 100.0, s.RV_Length / 100.0) AS RelLongRange,
				dbo.CalculateX(s.B, s.HV_Slope, s.RV_Slope) AS X
			FROM (
				SELECT
					t.*,
					dbo.TimeToCollision(t.Calc_Range, t.Calc_RangeRate) As TCC,
					dbo.LongRange(t.NorthOffset, t.EastOffset, t.HV_Heading) AS LongRange,
					dbo.CalculateB(t.NorthOffset, t.EastOffset, t.HV_Slope) AS B,
					dbo.RVSlope(t.HV_Slope) AS RV_Slope
				FROM (
					SELECT 
						r.* ,
						-- validation..
						--r.HV_Location.Lat as HV_Lat,
						--r.HV_Latitude,
						--r.HV_Location.Long as HV_Long,
						--r.HV_Longitude,
						--r.RV_Location.Lat as RV_Lat,
						--r.RV_Latitude,
						--r.RV_Location.Long as RV_Long,
						--r.RV_Longitude,
						dbo.Range(r.RV_Location, r.HV_Location) AS [Calc_Range],
						--r.RV_Range,
						
						--r.HV_Heading HV_Heading,
						--r.HV_Length as HV_Length,
						--r.HV_Width as HV_Width,
						--r.RV_Length as RV_Length,
						--r.RV_Width as RV_Width,
						--r.HV_Speed as HV_Speed,
						--r.RV_Speed as RV_Speed,
						--r.RV_Location.Lat as Lat,
						--r.RV_Location.Long as Long,

						(0.65 * (dbo.Range(r.RV_Location, r.HV_Location) - dbo.Range(LAG(r.RV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC)))) +
						(0.25 * (dbo.Range(LAG(r.RV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC)) - dbo.Range(LAG(r.RV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC)))) +
						(0.1 * (dbo.Range(LAG(r.RV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC)) - dbo.Range(LAG(r.RV_Location, 3) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 3) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC)))) AS ScaledDRange,
	
						ABS(DATEDIFF(MILLISECOND, r.Date_Time, LAG(r.Date_Time, 3) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC))) / 3  * 0.001 AS dt,

						dbo.RangeRate(0.65 * (dbo.Range(r.RV_Location, r.HV_Location) - dbo.Range(LAG(r.RV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC))) +
						0.25 * (dbo.Range(LAG(r.RV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 1) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC)) - dbo.Range(LAG(r.RV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC))) +
						0.1 * (dbo.Range(LAG(r.RV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 2) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC)) - dbo.Range(LAG(r.RV_Location, 3) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC), LAG(r.HV_Location, 3) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC))),
						ABS(DATEDIFF(MILLISECOND, r.Date_Time, LAG(r.Date_Time, 3) OVER (PARTITION BY r.HV_ID, r.RV_ID ORDER BY r.Time ASC))) / 3 * 0.001) AS Calc_RangeRate,
						--r.RV_RangeRate

						dbo.NorthOffset(r.RV_Location, r.HV_Location) as NorthOffset,
						dbo.EastOffset(r.RV_Location, r.HV_Location) as EastOffset,
						dbo.HVSlope(r.HV_heading) as HV_Slope,
						dbo.DistanceToPointOfInterestInMeters(r.hv_latitude, r.hv_longitude, r.rv_latitude, r.rv_longitude) AS Distance
					FROM [hivedb].[dbo].[SafetyPilotTestData] r
				) AS t
			) AS s
		) AS u
	) AS v
) AS w
ORDER BY 
	w.HV_ID, 
	w.Time ASC
