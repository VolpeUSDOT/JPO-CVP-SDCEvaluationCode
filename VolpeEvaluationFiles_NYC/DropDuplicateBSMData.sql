--Drop duplicate BSM records

Use NYCDB
Go 

with CTE as(
select * from (
Select row_number() over (partition by eventtype, volpeid, time order by SeqNum) rownum, *
  from [NYCDB].[dbo].[HostVehicleData]) t )
delete from CTE where rownum > 1
Go

with CTE as(
select * from (
Select row_number() over (partition by eventtype, volpeid, time order by SeqNum) rownum, *
  from [NYCDB].[dbo].[TargetVehicleData]) t )
delete from CTE where rownum > 1
Go

