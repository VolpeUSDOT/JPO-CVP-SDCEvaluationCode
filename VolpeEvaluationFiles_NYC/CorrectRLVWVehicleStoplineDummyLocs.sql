update t1
set 
t1.Xdeg = (t1.X - t2.minX)* 9.01E-6 + 0.000001,
t1.Ydeg = (t1.Y - t2.minY)* 9.01E-6 + 0.000001,
t1.StopLineXdeg = (t1.StopLine.STX - t2.minX)* 9.01E-6 + 0.000001, 
t1.StopLineYdeg = (t1.StopLine.STY - t2.minY)* 9.01E-6 + 0.000001
From
HostVehicleDataRLVW_1 t1 join 
(
Select eventid, min(X) minX, min(Y) minY
from (
	Select eventid, a.x X, a.y Y from HostVehicleDataRLVW_1 a
	union 
	Select eventid, b.StopLine.STX X, b.StopLine.STY Y from HostVehicleDataRLVW_1 b
) t
group by eventid
) t2 on t1.eventid=t2.eventid

Go