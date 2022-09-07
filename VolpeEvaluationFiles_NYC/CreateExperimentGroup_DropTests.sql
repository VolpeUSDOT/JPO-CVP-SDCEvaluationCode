use NYCDB
Go

If COL_LENGTH('AllWarningEvent', 'ExperimentGroup') is null
Begin
Alter Table AllWarningEvent
add ExperimentGroup varchar(max) null
End

Go

Update AllWarningEvent
Set ExperimentGroup = 
case when grpid = 20 then 'control'
		when grpid >=21 then 'treatment'
		when grpid is null then 'null'
		else 'test' end

Go

with CTE as(
select * from AllWarningEvent)
delete from CTE where ExperimentGroup = 'test'
Go

with CTE as(
select * from AllWarningEvent)
delete from CTE where dummytime < '2021-01-01'
Go