
Use NYCDB

drop table if exists HostVehicleDataRLVW_1
go

Select b.*, E.WarningStartTime

into HostVehicleDataRLVW_1
from HostVehicleDataRLVW b
join AllWarningEvent E
on b.EventID = E.eventid
Go

Update b set
--Select top 1000
b.intersectionid = bt.intersectionid,
b.lanesetlaneid = bt.lanesetlaneid, 
b.signalgroup = bt.signalgroup, 
b.connectionid = bt.connectionid,
b.dist = b.Location.STDistance(bt.LaneGeometry),
b.LaneGeometry = bt.LaneGeometry,
b.StopLine = bt.StopLine,
b.LaneWidth = bt.LaneWidth,
b.StopLineXdeg = bt.StopLineXdeg,
b.StopLineYdeg = bt.StopLineYdeg

From HostVehicleDataRLVW_1 b
join (Select * from HostVehicleDataRLVW_1 where Time = WarningStartTime) bt
on b.EventID = bt.EventID
Go

Update b set 
	 b.SignalState = (Select top 1 s.SignalState from
	 SPaTSignal_TimeStates s
where b.EventID = s.EventID and b.intersectionid = s.intersectionid and b.signalgroup = s.signalgroup and (s.Time = b.Time)  and ((b.connectionid = s.connectionid) or (s.connectionid is null))
order by time desc
)
From HostVehicleDataRLVW_1 b 
GO

Update b set
b.SignalState = c.SignalState_1
	
From HostVehicleDataRLVW_1 b 
join (
SELECT eventid, Time, X, Y, Speed, intersectionid, lanesetlaneid, signalgroup, SignalState, StopLineXdeg, StopLineYdeg,
	CAST(SUBSTRING(MAX(CAST(Time as Binary(32)) + CAST(SignalState as Binary(32))) 
	OVER (partition by eventid Order by time asc rows unbounded preceding), 33, 30) as varchar(max)) SignalState_1
	
  FROM [NYCDB].[dbo].[HostVehicleDataRLVW_1]
) c
on b.eventid = c.eventid and b.time = c.time
Go