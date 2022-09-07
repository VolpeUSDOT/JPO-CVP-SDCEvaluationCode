Use NYCDB

drop table if exists HostVehicleDataRLVW
go

Select *, geometry::STGeomFromText('POINT(' + STR(X, 16, 12) 
	+ ' ' + STR(Y, 16, 12) + ')', 0) as [Location]

into HostVehicleDataRLVW
from HostVehicleData where EventType = 'rlvw'

Alter table HostVehicleDataRLVW
Add intersectionid varchar(max), lanesetlaneid bigint, signalgroup bigint, connectionid float, dist float

Update b set 
	 intersectionid  = (
		select top 1 intersectionid from MAPLaneGeometries
		where EventID = b.EventID and b.Location.STDistance(LaneGeometry) < 3
		order by b.Location.STDistance(LaneGeometry)
		) ,
	lanesetlaneid = (
		select top 1 lanesetlaneid from MAPLaneGeometries
		where EventID = b.EventID and b.Location.STDistance(LaneGeometry) < 3
		order by b.Location.STDistance(LaneGeometry)
		) ,
	signalgroup = (
		select top 1 signalgroup from MAPLaneGeometries
		where EventID = b.EventID and b.Location.STDistance(LaneGeometry) < 3
		order by b.Location.STDistance(LaneGeometry)
		) ,
	connectionid = (
		select top 1 connectionid from MAPLaneGeometries
		where EventID = b.EventID and b.Location.STDistance(LaneGeometry) < 3
		order by b.Location.STDistance(LaneGeometry)
		),
	dist = (
		select top 1 b.Location.STDistance(LaneGeometry) from MAPLaneGeometries
		where EventID = b.EventID
		order by b.Location.STDistance(LaneGeometry)
		)
From HostVehicleDataRLVW b
GO

Alter table HostVehicleDataRLVW
Add SignalState varchar(max)
GO

Update b set 
	 b.SignalState = (Select top 1 s.SignalState from
	 SPaTSignal_TimeStates s
where b.EventID = s.EventID and b.intersectionid = s.intersectionid and b.signalgroup = s.signalgroup and (s.Time between b.Time - 5 and b.Time)  and ((b.connectionid = s.connectionid) or (s.connectionid is null))
)
From HostVehicleDataRLVW b 
GO