USE NYCDB

IF EXISTS(SELECT 1 FROM NYCDB.sys.columns 
          WHERE Name = N'LaneGeometry'
          AND Object_ID = Object_ID(N'NYCDB.dbo.MAPLaneGeometries'))
BEGIN
    ALTER TABLE NYCDB.dbo.MAPLaneGeometries
	DROP COLUMN [LaneGeometry]
END

ALTER TABLE NYCDB.dbo.MAPLaneGeometries
ADD [LaneGeometry] AS geometry::STGeomFromText(nodeList, 0) PERSISTED

