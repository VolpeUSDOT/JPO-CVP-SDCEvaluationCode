SELECT 
	w.* ,
	dbo.TimeToIntersection(w.LongRange, w.HV_Speed) as TTI_LongRange_HV,
	dbo.TimeToIntersection(w.LatRange, w.RV_Speed) as TTI_LatRange_RV
FROM (
	SELECT
		v.hostobuip,
		v.hostdatetime,
		v.Range,
		v.RangeRate,
		v.TCC,
		v.LongRange,
		v.LatRange,
		v.RelLongRange,
		v.RelLatRange,
		dbo.PreciseRelativeLocation(v.HV_Heading, v.RV_Heading, v.RelLongRange, v.RelLatRange, v.HV_Length, v.HV_Width, v.RV_Length, v.RV_Width, v.LongRange, v.LatRange) AS PreciseRelativeLocation,
		v.HV_Speed,
		v.RV_Speed,
		v.HV_Slope,
		v.RV_Slope,
		v.B,
		v.X,
		v.Y,
		dbo.HVTTIBasedOnDtI(v.X, v.Y, v.HV_Speed) AS HVTTI,
		dbo.RVTTIBasedOnDtI(v.EastOffset, v.X, v.NorthOffset, v.Y, v.RV_Speed) AS RVTTI,
		v.Distance,
		dbo.TimeToPointOfInterest(v.Distance, v.HV_Speed) AS TTPOI
	FROM (
		SELECT
			u.hostobuip,
			u.hostdatetime,
			u.Range,
			u.RangeRate,
			u.TCC,
			u.LongRange,
			u.LatRange,
			u.RelLongRange,
			dbo.RelLatRange(u.LatRange, u.HV_Width / 100.0, u.RV_Width / 100.0) AS RelLatRange,
			u.HV_Length,
			u.RV_Length,
			u.HV_Width,
			u.RV_Width,
			u.HV_Heading,
			u.RV_Heading,
			u.HV_Speed,
			u.RV_Speed,
			u.HV_Slope,
			u.RV_Slope,
			u.B,
			u.X,
			dbo.CalculateY(u.HV_Slope, u.X) AS Y,
			u.NorthOffset,
			u.EastOffset,
			u.Distance
		FROM (
			SELECT
				s.hostobuip,
				s.hostdatetime,
				s.Range,
				s.RangeRate,
				s.TCC,
				s.LongRange,
				dbo.LatRange(s.Range, s.LongRange, s.NorthOffset, s.EastOffset, s.HV_Heading) AS LatRange,
				s.HV_Length,
				s.RV_Length,
				dbo.RelLongRange(s.LongRange, s.HV_Length / 100.0, s.RV_Length / 100.0) AS RelLongRange,
				s.HV_Width,
				s.RV_Width,
				s.HV_Heading,
				s.RV_Heading,
				s.HV_Speed,
				s.RV_Speed,
				s.HV_Slope,
				s.RV_Slope,
				s.B,
				dbo.CalculateX(s.B, s.HV_Slope, s.RV_Slope) AS X,
				s.NorthOffset,
				s.EastOffset,
				s.Distance
			FROM (
				SELECT
					t.hostobuip, 
					t.hostdatetime,
					t.Range,
					t.ScaledDRange,
					t.dt,
					t.RangeRate,
					dbo.TimeToCollision(t.Range, t.RangeRate) As TCC,
					t.NorthOffset,
					t.EastOffset,
					t.HV_Heading,
					dbo.LongRange(t.NorthOffset, t.EastOffset, t.HV_Heading) AS LongRange,
					t.HV_Length,
					t.HV_Width,
					t.RV_Length,
					t.RV_Width,
					t.heading AS RV_Heading,
					t.HV_Speed,
					t.RV_Speed,
					t.HV_Slope,
					dbo.RVSlope(t.HV_Slope) AS RV_Slope,
					dbo.CalculateB(t.NorthOffset, t.EastOffset, t.HV_Slope) AS B,
					t.Distance

				FROM (
					SELECT 
						r.*, 
						h.heading as HV_Heading,
						h.length as HV_Length,
						h.width as HV_Width,
						r.length as RV_Length,
						r.width as RV_Width,
						h.speed as HV_Speed,
						r.speed as RV_Speed,
						dbo.Range(r.Location, r.HostLocation) AS [Range],

						(0.65 * (dbo.Range(r.Location, r.HostLocation) - dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC)))) +
						(0.25 * (dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC)) - dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC)))) +
						(0.1 * (dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC)) - dbo.Range(LAG(r.Location, 3) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 3) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC)))) AS ScaledDRange,
	
						ABS(DATEDIFF(MILLISECOND, r.hostdatetime, LAG(r.hostdatetime, 3) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC))) / 3  * 0.001 AS dt,
	
						dbo.RangeRate(0.65 * (dbo.Range(r.Location, r.HostLocation) - dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC))) +
						0.25 * (dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 1) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC)) - dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC))) +
						0.1 * (dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 2) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC)) - dbo.Range(LAG(r.Location, 3) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC), LAG(r.HostLocation, 3) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC))),
						ABS(DATEDIFF(MILLISECOND, r.hostdatetime, LAG(r.hostdatetime, 3) OVER (PARTITION BY r.hostobuip ORDER BY r.hostobuip, r.hostdatetime ASC))) / 3 * 0.001) AS RangeRate,

						dbo.NorthOffset(r.Location, r.HostLocation) as NorthOffset,
						dbo.EastOffset(r.Location, r.HostLocation) as EastOffset,
						dbo.HVSlope(h.heading) as HV_Slope,
						dbo.DistanceToPointOfInterestInMeters(h.latitude, h.longitude, r.latitude, r.longitude) AS Distance

					FROM sampleBSMDataFCW20190806_remote r
					JOIN dbo.sampleBSMDataFCW20190806_Host h ON h.hostobuip = r.hostobuip AND h.hostdatetime = r.hostdatetime
				) AS t
			) AS s
		) AS u
	) AS v
) AS w
ORDER BY 
	w.hostobuip, 
	w.hostdatetime ASC
