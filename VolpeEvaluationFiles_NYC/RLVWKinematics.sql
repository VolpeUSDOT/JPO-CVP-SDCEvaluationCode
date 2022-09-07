USE NYCDB

drop table if exists NYCDB.dbo.Volpe_NYC_Veh_Event_RLVW_Kinematics_1

Select
	w.* ,
	dbo.TimeToIntersection(w.LongRange, w.HV_Speed) as TTI_LongRange_HV,
	dbo.TimeToIntersection(w.LatRange, w.Lane_Speed) as TTI_LatRange_RV
into NYCDB.dbo.Volpe_NYC_Veh_Event_RLVW_Kinematics_1
FROM (
	SELECT
		v.hostVehicleID,
		v.eventType,
		v.VolpeID,
		v.Time,
		v.HVX,
		v.HVY,
		v.StopLineX,
		v.StopLineY,
		v.HV_Ydeg,
		v.HV_Xdeg,
		v.intersectionid,
		v.laneid,
		v.StopLineYdeg,
		v.StopLineXdeg,
		v.SignalState,
		v.Range,
		v.RangeRate,
		v.TTC,
		v.LongRange,
		v.LatRange,
		v.RelLongRange as RelLongLocation,
		v.RelLatRange as RelLatLocation,
		v.HV_Heading,
		v.Lane_Angle,
		v.HV_Length,
		v.HV_Width,
		v.Lane_Length,
		v.Lane_Width,
		dbo.PreciseRelativeLocation(v.HV_Heading, v.Lane_Angle, v.RelLongRange, v.RelLatRange, v.HV_Length, v.HV_Width, v.Lane_Length, v.Lane_Width, v.LongRange, v.LatRange) AS PreciseRelativeLocation,
		v.HV_Speed,
		v.Lane_Speed,
		v.HV_Slope,
		v.Lane_Slope,
		v.B,
		v.X,
		v.Y,
		dbo.HVTTIBasedOnDtI(v.X, v.Y, v.HV_Speed) AS HVTTI,
		dbo.RVTTIBasedOnDtI(v.EastOffset, v.X, v.NorthOffset, v.Y, v.Lane_Speed) AS RVTTI,
		v.Distance,
		dbo.TimeToPointOfInterest(v.Distance, v.HV_Speed) AS TTPOI
	FROM (
		SELECT
			u.hostVehicleID,
			u.eventType,
			u.VolpeID,
			u.Time,
			u.HVX,
			u.HVY,
			u.StopLineX,
			u.StopLineY,
			u.HV_Ydeg,
			u.HV_Xdeg,
			u.intersectionid,
			u.laneid,
			u.StopLineYdeg,
			u.StopLineXdeg,
			u.SignalState,
			u.Range,
			u.RangeRate,
			u.TTC,
			u.LongRange,
			u.LatRange,
			u.RelLongRange,
			dbo.RelLatRange(u.LatRange, u.HV_Width-.15, u.Lane_Width-.15) AS RelLatRange,
			u.HV_Length,
			u.Lane_Length,
			u.HV_Width,
			u.Lane_Width,
			u.HV_Heading,
			u.Lane_Angle,
			u.HV_Speed,
			u.Lane_Speed,
			u.HV_Slope,
			u.Lane_Slope,
			u.B,
			u.X,
			dbo.CalculateY(u.HV_Slope, u.X) AS Y,
			u.NorthOffset,
			u.EastOffset,
			u.Distance
		FROM (
			SELECT
				s.hostVehicleID,
				s.eventType,
				s.VolpeID,
				s.Time,
				s.HVX,
				s.HVY,
				s.StopLineX,
				s.StopLineY,
				s.HV_Ydeg,
				s.HV_Xdeg,
				s.intersectionid,
				s.laneid,
				s.StopLineYdeg,
				s.StopLineXdeg,
				s.SignalState,
				s.Range,
				s.RangeRate,
				s.TTC,
				s.LongRange,
				dbo.LatRange(s.Range, s.LongRange, s.NorthOffset, s.EastOffset, s.HV_Heading) AS LatRange,
				s.HV_Length,
				s.Lane_Length,
				dbo.RelLongRange(s.LongRange, s.HV_Length, s.Lane_Length) AS RelLongRange,
				s.HV_Width,
				s.Lane_Width,
				s.HV_Heading,
				s.Lane_Angle,
				s.HV_Speed,
				s.Lane_Speed,
				s.HV_Slope,
				s.Lane_Slope,
				s.B,
				dbo.CalculateX(s.B, s.HV_Slope, s.Lane_Slope) AS X,
				s.NorthOffset,
				s.EastOffset,
				s.Distance
			FROM (
				SELECT
					t.hostVehicleID,
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
					t.StopLineX,
					t.StopLineY,
					t.HV_Ydeg,
					t.HV_Xdeg,
					t.intersectionid,
					t.laneid,
					t.StopLineYdeg,
					t.StopLineXdeg,
					t.SignalState,
					t.NorthOffset,
					t.EastOffset,
					t.HV_Heading,
					dbo.LongRange(t.NorthOffset, t.EastOffset, t.HV_Heading) AS LongRange,
					t.HV_Length,
					t.HV_Width,
					t.Lane_Length,
					t.Lane_Width,
					t.Lane_Angle,
					t.HV_Speed,
					t.Lane_Speed,
					t.HV_Slope,
					dbo.RVSlope(t.HV_Slope) AS Lane_Slope,
					dbo.CalculateB(t.NorthOffset, t.EastOffset, t.HV_Slope) AS B,
					t.Distance

				FROM (
					SELECT 
						h.hostVehicleID,
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
						h.intersectionid,
						h.lanesetlaneid laneid,
						h.StopLine.STX as StopLineX,
						h.StopLine.STY as StopLineY,
						h.StopLineYdeg as StopLineYdeg,
						h.StopLineXdeg as StopLineXdeg,
						h.SignalState,
						90 - 57.296*ATN2(h.LaneGeometry.STStartPoint().STY-h.LaneGeometry.STEndPoint().STY, h.LaneGeometry.STStartPoint().STX-h.LaneGeometry.STEndPoint().STX) as Lane_Angle,
						cast(LaneGeometry.STStartPoint().STDistance(LaneGeometry.STEndPoint()) as float)/100 as Lane_Length,
						cast(h.LaneWidth as float)/100 as Lane_Width,
						h.Speed as HV_Speed,
						0 as Lane_Speed,
						dbo.Range(h.StopLineLocation, h.HostLocation) AS [Range],
						--Scaled Delta Range
						(  0.65 * (dbo.Range(h.StopLineLocation, h.HostLocation) 
									- dbo.Range(LAG(h.StopLineLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
						+ (0.25 * (dbo.Range(LAG(h.StopLineLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(h.StopLineLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
						+ (0.10 * (dbo.Range(LAG(h.StopLineLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(h.StopLineLocation, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)))) 
						AS ScaledDRange,
	
						ABS(DATEDIFF(MILLISECOND, h.dummytime, LAG(h.dummytime, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.dummytime ASC))) / 3  * 0.001 AS dt,
						---Range Rate
						dbo.RangeRate(
							(0.65 * (dbo.Range(h.StopLineLocation, h.HostLocation) 
									- dbo.Range(LAG(h.StopLineLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
							+ (0.25 * (dbo.Range(LAG(h.StopLineLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 1) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(h.StopLineLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC))))
							+ (0.10 * (dbo.Range(LAG(h.StopLineLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 2) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)) 
									- dbo.Range(LAG(h.StopLineLocation, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC), 
												LAG(h.HostLocation, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.Time ASC)))),
							
							ABS(DATEDIFF(MILLISECOND, h.dummytime, LAG(h.dummytime, 3) OVER (PARTITION BY h.hostVehicleID, h.eventType, h.VolpeID ORDER BY h.hostvehicleid, h.eventType, h.VolpeID, h.dummytime ASC))) / 3  * 0.001
						)
						AS RangeRate,

						dbo.NorthOffset(h.StopLineLocation, h.HostLocation) as NorthOffset,
						dbo.EastOffset(h.StopLineLocation, h.HostLocation) as EastOffset,
						dbo.HVSlope(h.Heading) as HV_Slope,
						dbo.DistanceToPointOfInterestInMeters(h.Ydeg, h.Xdeg, h.StopLineYdeg, h.StopLineXdeg) AS Distance

					FROM NYCDB.dbo.HostVehicleDataRLVWLoc_1 h
	
				) AS t
			) AS s
		) AS u
	) AS v
) AS w
ORDER BY 
	w.hostVehicleID, 
	w.Time ASC
