USE NYCDB

drop table if exists NYCDB.dbo.Volpe_NYC_Veh_Event_Kinematics

Select
	w.* ,
	dbo.TimeToIntersection(w.LongRange, w.HV_Speed) as TTI_LongRange_HV,
	dbo.TimeToIntersection(w.LatRange, w.RV_Speed) as TTI_LatRange_RV
into NYCDB.dbo.Volpe_NYC_Veh_Event_Kinematics
FROM (
	SELECT
		v.hostVehicleID,
		v.remoteVehicleID,
		v.eventType,
		v.VolpeID,
		v.Time,
		v.HVX,
		v.HVY,
		v.RVX,
		v.RVY,
		v.HV_Ydeg,
		v.HV_Xdeg,
		v.RV_Ydeg,
		v.RV_Xdeg,
		v.Range,
		v.RangeRate,
		v.TTC,
		v.LongRange,
		v.LatRange,
		v.RelLongRange as RelLongLocation,
		v.RelLatRange as RelLatLocation,
		v.HV_Heading,
		v.RV_Heading,
		v.HV_Length,
		v.HV_Width,
		v.RV_Length,
		v.RV_Width,
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
			u.hostVehicleID,
			u.remoteVehicleID,
			u.eventType,
			u.VolpeID,
			u.Time,
			u.HVX,
			u.HVY,
			u.RVX,
			u.RVY,
			u.HV_Ydeg,
			u.HV_Xdeg,
			u.RV_Ydeg,
			u.RV_Xdeg,
			u.Range,
			u.RangeRate,
			u.TTC,
			u.LongRange,
			u.LatRange,
			u.RelLongRange,
			dbo.RelLatRange(u.LatRange, u.HV_Width-.15, u.RV_Width-.15) AS RelLatRange,
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
				s.hostVehicleID,
				s.remoteVehicleID,
				s.eventType,
				s.VolpeID,
				s.Time,
				s.HVX,
				s.HVY,
				s.RVX,
				s.RVY,
				s.HV_Ydeg,
				s.HV_Xdeg,
				s.RV_Ydeg,
				s.RV_Xdeg,
				s.Range,
				s.RangeRate,
				s.TTC,
				s.LongRange,
				dbo.LatRange(s.Range, s.LongRange, s.NorthOffset, s.EastOffset, s.HV_Heading) AS LatRange,
				s.HV_Length,
				s.RV_Length,
				dbo.RelLongRange(s.LongRange, s.HV_Length, s.RV_Length) AS RelLongRange,
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
					t.hostVehicleID,
					t.remoteVehicleID,
					t.eventType,
					t.VolpeID,
					t.Time,
					t.Range,
					t.ScaledDRange,
					t.dt,
					t.RangeRate,
					CASE 
						WHEN t.RangeRate < 0 
							THEN dbo.TimeToCollision(t.Range, -t.RangeRate) 
						ELSE NULL 
						END As TTC,
					t.HVX,
					t.HVY,
					t.RVX,
					t.RVY,
					t.HV_Ydeg,
					t.HV_Xdeg,
					t.RV_Ydeg,
					t.RV_Xdeg,
					t.NorthOffset,
					t.EastOffset,
					t.HV_Heading,
					dbo.LongRange(t.NorthOffset, t.EastOffset, t.HV_Heading) AS LongRange,
					t.HV_Length,
					t.HV_Width,
					t.RV_Length,
					t.RV_Width,
					t.RV_Heading,
					t.HV_Speed,
					t.RV_Speed,
					t.HV_Slope,
					dbo.RVSlope(t.HV_Slope) AS RV_Slope,
					dbo.CalculateB(t.NorthOffset, t.EastOffset, t.HV_Slope) AS B,
					t.Distance

				FROM (
					SELECT 
						h.hostVehicleID,
						r.remoteVehicleID,
						h.eventType,
						h.VolpeID,
						h.Time,
						h.X as HVX,
						h.Y as HVY,
						h.Ydeg as HV_Ydeg,
						h.Xdeg as HV_Xdeg,
						h.Heading as HV_Heading,
						Cast(h.Length as float)/100.0 as HV_Length,
						cast(h.Width as float)/100.0 as HV_Width,
						r.X as RVX,
						r.Y as RVY,
						r.Ydeg as RV_Ydeg,
						r.Xdeg as RV_Xdeg,
						r.Heading as RV_Heading,
						cast(r.Length as float)/100 as RV_Length,
						cast(r.Width as float)/100 as RV_Width,
						h.Speed as HV_Speed,
						r.Speed as RV_Speed,
						dbo.Range(r.Location, h.Location) AS [Range],
						--Scaled Delta Range
						(  0.65 * (dbo.Range(r.Location, h.Location) 
									- dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
						+ (0.25 * (dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
						+ (0.10 * (dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 3) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)))) 
						AS ScaledDRange,
	
						ABS(DATEDIFF(MILLISECOND, h.dummytime, LAG(h.dummytime, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.dummytime ASC))) / 3  * 0.001 AS dt,
						---Range Rate
						dbo.RangeRate(
							(0.65 * (dbo.Range(r.Location, h.Location) 
									- dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
							+ (0.25 * (dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
							+ (0.10 * (dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 3) OVER (PARTITION BY r.remoteVehicleID, r.eventType, r.VolpeID ORDER BY r.remoteVehicleID, r.eventType, r.VolpeID, r.Time ASC), 
												LAG(h.Location, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)))),
							
							ABS(DATEDIFF(MILLISECOND, h.dummytime, LAG(h.dummytime, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.dummytime ASC))) / 3  * 0.001
						)
						AS RangeRate,

						dbo.NorthOffset(r.Location, h.Location) as NorthOffset,
						dbo.EastOffset(r.Location, h.Location) as EastOffset,
						dbo.HVSlope(h.Heading) as HV_Slope,
						dbo.DistanceToPointOfInterestInMeters(h.Ydeg, h.Xdeg, r.Ydeg, r.Xdeg) AS Distance

					FROM NYCDB.dbo.HostVehicleDataloc h
					JOIN NYCDB.dbo.TargetVehicleDataloc r 
					ON h.VolpeID = r.VolpeID AND h.eventType = r.eventType AND h.Time = r.Time
				) AS t
			) AS s
		) AS u
	) AS v
) AS w
ORDER BY 
	w.hostVehicleID, 
	w.Time ASC
