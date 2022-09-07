-- Create Warning Start Time

Update HostVehicleData
Set Time = ROUND(Time, 1)

Update TargetVehicleData
Set Time = ROUND(Time, 1)
Go

Use NYCDB
If COL_LENGTH('AllWarningEvent', 'WarningStartTime') is null
Begin
Alter Table AllWarningEvent
add WarningStartTime float
End

GO

Update E
Set E.WarningStartTime = bh.Time, E.dummytime = DATEADD(Second, bh.Time, E.dummytime)
From 
AllWarningEvent E
Join HostVehicleData bh
on E.eventid = bh.EventID and E.SeqNumHV = bh.SeqNum