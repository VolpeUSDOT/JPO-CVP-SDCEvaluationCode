/****** Script for SelectTopNRows command from SSMS  ******/

USE NYCDB

If COL_LENGTH('HostVehicleDataRLVW', 'LaneGeometry') is null
Begin
Alter table HostVehicleDataRLVW
Add LaneGeometry geometry
end
GO

If COL_LENGTH('HostVehicleDataRLVW', 'StopLine') is null
Begin
Alter table HostVehicleDataRLVW
Add StopLine geometry
end
GO

If COL_LENGTH('HostVehicleDataRLVW', 'LaneWidth') is null
Begin
Alter table HostVehicleDataRLVW
Add LaneWidth bigint
end
GO

IF  1=1
update b 
set b.LaneGeometry = m.LaneGeometry, b.LaneWidth = m.LaneWidth
  FROM [NYCDB].[dbo].[HostVehicleDataRLVW] b
  join MAPLaneGeometries m
  on b.eventid = m.eventid and b.intersectionid = m.intersectionid and b.lanesetlaneid = m.lanesetlaneid

Go



update b
set StopLine = t3.stopLine
from HostVehicleDataRLVW b
join 
(Select BSMID, stopLine from (
Select BSMID, VolpeID, hostvehicleid, Time, Location,
heading, lanesetlaneid, 
x1p, y1p, x2p, y2p,
CASE 
	when x1p > 0 and x2p > 0
	then null
	when x1p < 0 and x2p < 0
	then CASE
			when x1p > x2p then point1
			when x2p > x1p then point2
			else null
		end
	when x1p > 0 and x2p < 0
	then point1
	when x2p > 0 and x1p < 0
	then point2
	else null
end stopLine, SignalState, LaneGeometry
From
( Select BSMID, VolpeID, hostvehicleid, Time, heading, lanesetlaneid,  LaneGeometry.STStartPoint() point1,
LaneGeometry.STEndPoint() point2, x1*cos(heading) + y1*sin(heading) x1p, y1*cos(heading) - x1*sin(heading) y1p, x2*cos(heading) + y2*sin(heading) x2p, y2*cos(heading) - x2*sin(heading) y2p
, Location, LaneGeometry, SignalState
From (
Select BSMID, VolpeID, hostvehicleid, Time, lanesetlaneid, (90-heading)*0.0174533 heading, X, Y, 
LaneGeometry.STStartPoint().STX-X x1,LaneGeometry.STStartPoint().STY-Y y1,
LaneGeometry.STEndPoint().STX-X x2,LaneGeometry.STEndPoint().STY-Y y2,
Location, LaneGeometry, SignalState
From HostVehicleDataRLVW
) t
) t1) t2) t3 on t3.BSMID = b.BSMID

Go

If COL_LENGTH('HostVehicleDataRLVW', 'StopLineXdeg') is null
Begin
Alter Table HostVehicleDataRLVW
add StopLineXdeg float
End

Go

If COL_LENGTH('HostVehicleDataRLVW', 'StopLineYdeg') is null
Begin
Alter Table HostVehicleDataRLVW
add StopLineYdeg float
End

Go

update t1
set t1.StopLineXdeg = (t1.StopLine.STX - t2.minX)* 9.01E-6 + 0.000001, t1.StopLineYdeg = (t1.StopLine.STY - t2.minY)* 9.01E-6 + 0.000001
From
HostVehicleDataRLVW t1 join 
(
Select eventid, min(X) minX, min(Y) minY
from (
Select eventid, x, y from HostVehicleData
) t
group by eventid
) t2 on t1.eventid=t2.eventid

Go



