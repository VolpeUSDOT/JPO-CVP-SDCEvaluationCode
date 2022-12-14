
SELECT a.hostVehicleID HostVehID, d.vehicleType VehicleType, 
SUM( CASE WHEN a.RelLongLocation = 'Front' AND a.RelLatLocation = 'Center' AND a.Range < 120
	 AND ABS(b.Elevation - c.Elevation) < 4.3 AND -- min clearance 14 ft
	 (	ABS(a.HV_Heading - a.RV_Heading) <= 10 
		OR (HV_Heading BETWEEN 0 AND 10 AND (RV_Heading < HV_Heading+10 OR RV_Heading > HV_Heading+350))
		OR (HV_Heading BETWEEN 350 AND 360 AND (RV_Heading < HV_Heading-350 OR RV_Heading > HV_Heading-10))) 
	THEN 1 ELSE NULL END )/10/60.0 AS ForwardInPathTarget,
SUM( CASE WHEN a.RelLongLocation = 'Front' AND a.RelLatLocation IN('Left','Right') AND a.Range < 120
	 AND ABS(b.Elevation - c.Elevation) < 4.3 AND -- min clearance 14 ft
	 (	ABS(a.HV_Heading - a.RV_Heading) <= 10 
		OR (HV_Heading BETWEEN 0 AND 10 AND (RV_Heading < HV_Heading+10 OR RV_Heading > HV_Heading+350))
		OR (HV_Heading BETWEEN 350 AND 360 AND (RV_Heading < HV_Heading-350 OR RV_Heading > HV_Heading-10))) 
	THEN 1 ELSE NULL END )/10/60.0 AS ForwardOutofPathTarget,

SUM( CASE WHEN PreciseRelativeLocation like '%ima%' --and a.hostVehicleID = '1AD' AND a.remoteVehicleID = '2300070' 
	 AND a.LongRange < 120 AND ABS(latRange) < 120
	 AND ABS(b.Elevation - c.Elevation) < 4.3 -- min clearance 14 ft
	 THEN 1 ELSE NULL END )/10/60.0 AS ImaTarget,
SUM( CASE WHEN
	 (	hostVehicleID IN ('1AD','1AE','1AF','1B1','1B2','1B4', '98982D','98982E','98982F','989831','989832','989833','989834')
		   OR remoteVehicleID IN ('429','430','431','433','434','436','10000429','10000430','10000431','10000433','10000434','10000435','10000436') )
		AND ABS(a.LongRange) <= 50 --- based on aler long range
		AND ABS(a.LatRange) <= 11.1 --- based on 3 car lanewidths
		AND ABS(b.Elevation - c.Elevation) < 4.3 -- min clearance 14 ft
		AND ABS(a.HV_Heading - RV_Heading) <= 10
		THEN 1 ELSE NULL END 
	 )/10/60.0 AS VtrftvTarget
INTO #V2V_Exposure
FROM [THEADB_V2].[dbo].[Volpe_Thea_Exposure_Kinematics] a
LEFT JOIN THEADB_V2.dbo.Volpe_SentBSM_InterpedInteractionDataLoc b
ON a.hostVehicleID = b.HostVehID AND a.remoteVehicleID = b.RV_ID AND a.Time = b.Time
LEFT JOIN THEADB_V2.dbo.Volpe_Thea_ReceivedBSM_Loc c
ON a.hostVehicleID = c.HostVehID AND a.remoteVehicleID = c.RV_ID AND a.Time = c.Time
LEFT JOIN THEADB_V2.dbo.Volpe_Thea_VehicleParticipantCategories d
ON a.hostVehicleID = d.vehicleID
--WHERE a.hostVehicleID = '1AD' AND a.remoteVehicleID = '10000435' 
GROUP BY a.hostVehicleID, d.vehicleType
ORDER BY a.hostVehicleID



Select a.*, b.*
FROM #V2V_Exposure a 
LEFT JOIN 
(
	Select a.HostVehID, 
	SUM(CASE WHEN WarningType = 'FCW' THEN 1 ELSE 0 END) FCWcount,
	SUM(CASE WHEN WarningType = 'FCW' AND IsValidAlert = 1 THEN 1 ELSE 0 END) ValidFCWcount,
	SUM(CASE WHEN WarningType = 'FCW' AND IsValidAlert = 1 AND EventID NOT IN (214,262,139,146,217,256,288,239)THEN 1 ELSE 0 END) UsefulFCWcount,

	SUM(CASE WHEN WarningType = 'EEBL' THEN 1 ELSE 0 END) EEBLcount,
	SUM(CASE WHEN WarningType = 'EEBL' AND IsValidAlert = 1 THEN 1 ELSE 0 END) ValidEEBLcount,
	SUM(CASE WHEN WarningType = 'EEBL' AND IsValidAlert = 1 AND EventID NOT IN (1,5,13) THEN 1 ELSE 0 END) UsefulEEBLcount,

	SUM(CASE WHEN WarningType = 'IMA' THEN 1 ELSE 0 END) IMAcount,
	SUM(CASE WHEN WarningType = 'IMA' AND IsValidAlert = 1 THEN 1 ELSE 0 END) ValidIMAcount,

	SUM(CASE WHEN WarningType = 'VTRFTV' THEN 1 ELSE 0 END) VTRFTVcount,
	SUM(CASE WHEN WarningType = 'VTRFTV' AND IsValidAlert = 1 THEN 1 ELSE 0 END) ValidVTRFTVcount
	from
	(
		SELECT b.HostVehID, b.HV_ID, b.StartTime, cast(b.StartTime as datetime2(1)) AlertStartTime, a.*,
		CASE 
			WHEN a.WarningType = 'FCW' AND HV_onCollisionPath > 0 AND RV_RelativeLocation = 1  THEN 1
			WHEN a.WarningType = 'EEBL' AND HV_onCollisionPath > 0 AND RV_RelativeLocation IN (1,2)  THEN 1
			WHEN a.WarningType = 'IMA' AND HV_onCollisionPath > 0 THEN 1
			WHEN a.WarningType = 'VTRFTV' AND HV_onCollisionPath > 0 THEN 1
		ELSE 0 END IsValidAlert
		FROM [THEADB_V2].[dbo].[LoggerEventToSDC] a
		INNER JOIN THEADB_V2.dbo.Volpe_Thea_All_Warning_07312020 b
		ON a.WarningType = b.WarningType AND a.EventID = b.EventID
		WHERE a.WarningType IN( 'FCW',	'EEBL',	'IMA',	'VTRFTV')
	) a
	group by a.HostVehID
) b 
ON a.HostVehID = b.HostVehID
WHERE a.ForwardInPathTarget is not null  AND A.ForwardInPathTarget != 0 --FCW
--WHERE a.ForwardInPathTarget is not null AND a.ForwardOutofPathTarget is not null AND A.ForwardInPathTarget != 0 AND A.ForwardOutofPathTarget != 0--EEBL
--WHERE a.ImaTarget is not null  AND A.ImaTarget != 0 --IMA
--WHERE a.VtrftvTarget is not null AND A.VtrftvTarget != 0 --VTRFTV
order by a.HostVehID




