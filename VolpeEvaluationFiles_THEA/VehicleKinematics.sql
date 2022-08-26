USE THEADB_V2

insert into THEADB_V2.dbo.Volpe_Thea_Veh_Event_Kinematics SELECT 
	w.* ,
	dbo.TimeToIntersection(w.LongRange, w.HV_Speed) as TTI_LongRange_HV,
	dbo.TimeToIntersection(w.LatRange, w.RV_Speed) as TTI_LatRange_RV
FROM (
	SELECT
		v.hostVehicleID,
		v.remoteVehicleID,
		v.warningType,
		v.eventID,
		v.Time,
		v.HV_Latitude,
		v.HV_Longitude,
		v.RV_Latitude,
		v.RV_Longitude,
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
			u.warningType,
			u.eventID,
			u.Time,
			u.HV_Latitude,
			u.HV_Longitude,
			u.RV_Latitude,
			u.RV_Longitude,
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
				s.warningType,
				s.eventID,
				s.Time,
				s.HV_Latitude,
				s.HV_Longitude,
				s.RV_Latitude,
				s.RV_Longitude,
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
					t.warningType,
					t.eventID,
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
					t.HV_Latitude,
					t.HV_Longitude,
					t.RV_Latitude,
					t.RV_Longitude,
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
						h.warningType,
						h.eventID,
						h.Time,
						h.Latitude as HV_Latitude,
						h.Longitude as HV_Longitude,
						h.Heading as HV_Heading,
						h.Length as HV_Length,
						h.Width as HV_Width,
						r.Latitude as RV_Latitude,
						r.Longitude as RV_Longitude,
						r.Heading as RV_Heading,
						r.Length as RV_Length,
						r.Width as RV_Width,
						h.Speed as HV_Speed,
						r.Speed as RV_Speed,
						dbo.Range(r.Location, h.Location) AS [Range],
						--Scaled Delta Range
						(  0.65 * (dbo.Range(r.Location, h.Location) 
									- dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC))))
						+ (0.25 * (dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC))))
						+ (0.10 * (dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 3) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 3) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC)))) 
						AS ScaledDRange,
	
						ABS(DATEDIFF(MILLISECOND, h.Time, LAG(h.Time, 3) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC))) / 3  * 0.001 AS dt,
						---Range Rate
						dbo.RangeRate(
							(0.65 * (dbo.Range(r.Location, h.Location) 
									- dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC))))
							+ (0.25 * (dbo.Range(LAG(r.Location, 1) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 1) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC))))
							+ (0.10 * (dbo.Range(LAG(r.Location, 2) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 2) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC)) 
									- dbo.Range(LAG(r.Location, 3) OVER (PARTITION BY r.remotevehicleid, r.warningType, r.eventID ORDER BY r.remotevehicleid, r.warningType, r.eventID, r.Time ASC), 
												LAG(h.Location, 3) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC)))),
							
							ABS(DATEDIFF(MILLISECOND, h.Time, LAG(h.Time, 3) OVER (PARTITION BY h.hostVehicleID, h.warningType, h.eventID ORDER BY h.hostvehicleid, h.warningType, h.eventID, h.Time ASC))) / 3  * 0.001
						)
						AS RangeRate,

						dbo.NorthOffset(r.Location, h.Location) as NorthOffset,
						dbo.EastOffset(r.Location, h.Location) as EastOffset,
						dbo.HVSlope(h.Heading) as HV_Slope,
						dbo.DistanceToPointOfInterestInMeters(h.Latitude, h.Longitude, r.Latitude, r.Longitude) AS Distance

					FROM THEADB_V2.dbo.Volpe_SentBSM_interpedEventDataLoc h
					JOIN THEADB_V2.dbo.Volpe_ReceivedBSM_interpedEventDataLoc r ON h.eventID = r.eventID AND h.warningType = r.warningType AND h.Time = r.Time
				) AS t
			) AS s
		) AS u
	) AS v
) AS w
ORDER BY 
	w.hostVehicleID, 
	w.Time ASC
