Use NYCDB

If COL_LENGTH('AllWarningEvent', 'Xdeg') is null
Begin
Alter Table AllWarningEvent
add Xdeg float
End

Go

If COL_LENGTH('AllWarningEvent', 'Ydeg') is null
Begin
Alter Table AllWarningEvent
add Ydeg float
End

Go

update t1
set t1.Xdeg = t1.X - (t2.minX* 9.01E-6) + 0.000001, t1.Ydeg = t1.Y - (t2.minY* 9.01E-6) + 0.000001
From
AllWarningEvent t1 join 
(
Select eventid, min(X) minX, min(Y) minY
from (
Select eventid, x, y from HostVehicleData
union 
Select eventid, x, y from TargetVehicleData
) t
group by eventid
) t2 on t1.eventid=t2.eventid

Go

If COL_LENGTH('HostVehicleData', 'Xdeg') is null
Begin
Alter Table HostVehicleData
add Xdeg float
End

Go

If COL_LENGTH('HostVehicleData', 'Ydeg') is null
Begin
Alter Table HostVehicleData
add Ydeg float
End

Go

update t1
set t1.Xdeg = (t1.X - t2.minX)* 9.01E-6 + 0.000001, t1.Ydeg = (t1.Y - t2.minY)* 9.01E-6 + 0.000001
From
HostVehicleData t1 join 
(
Select eventid, min(X) minX, min(Y) minY
from (
Select eventid, x, y from HostVehicleData
union 
Select eventid, x, y from TargetVehicleData
) t
group by eventid
) t2 on t1.eventid=t2.eventid

Go

If COL_LENGTH('TargetVehicleData', 'Xdeg') is null
Begin
Alter Table TargetVehicleData
add Xdeg float
End

Go

If COL_LENGTH('TargetVehicleData', 'Ydeg') is null
Begin
Alter Table TargetVehicleData
add Ydeg float
End

Go

update t1
set t1.Xdeg = (t1.X - t2.minX)* 9.01E-6 + 0.000001, t1.Ydeg = (t1.Y - t2.minY)* 9.01E-6 + 0.000001
From
TargetVehicleData t1 join 
(
Select eventid, min(X) minX, min(Y) minY
from (
Select eventid, x, y from HostVehicleData
union 
Select eventid, x, y from TargetVehicleData
) t
group by eventid
) t2 on t1.eventid=t2.eventid

Go


