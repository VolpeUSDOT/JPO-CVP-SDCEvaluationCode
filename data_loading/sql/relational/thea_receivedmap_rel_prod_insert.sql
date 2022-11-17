----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from thea_receivedmap_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables:
--   thea_receivedmap_core
--   thea_receivedmap_genericlane
--   thea_receivedmap_genericlane_nodexy
--   thea_receivedmap_genericlane_connection
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create tables if needed
--------------------------------------------------
CREATE TABLE IF NOT EXISTS thea_receivedmap_core(
    mapid string,
    METADATALOGUPLOADEDAT timestamp,
    METADATAMSGCNT int,
    METADATABURSTCNT int,
    METADATABURSTID bigint,
    METADATAHOSTVEHICLEID string,
    METADATALOGPSID string,
    METADATARSULIST string,
    METADATARECEIVEDRSUTIMESTAMPS bigint,
    METADATADATALOGID string,
    METADATALOGGENERATEDAT timestamp,
    METADATAEVENTTYPE string,
    DOT3CHANNEL int,
    DOT3PSID string,
    DOT3SIGNALRXSTRENGTH int,
    DOT3DATARATE int,
    DOT3TIMESLOT int,
    MESSAGEID int,
    DATAMSGISSUEREVISION int,
    DATALAYERTYPE string,
    DATALAYERID int,
    DATAINTERSECTIONGEOMETRYID int,
    DATAINTERSECTIONGEOMETRYREVISION int,
    DATAINTERSECTIONGEOMETRYREFPOINTLAT int,
    DATAINTERSECTIONGEOMETRYREFPOINTLONG int,
    DATAINTERSECTIONGEOMETRYLANEWIDTH int
);
    
CREATE TABLE IF NOT EXISTS thea_receivedmap_genericlane(
    glid string,
    mapid string,
    LANEID int,
    INGRESSAPPROACH string,
    MANEUVERS bigint,
    LANEATTRIBUTESDIRECTIONALUSE int,
    LANEATTRIBUTESSHAREDWIDTH int,
    LANEATTRIBUTESLANETYPEVEHICLE int
);

CREATE TABLE IF NOT EXISTS thea_receivedmap_genericlane_nodexy(
    glid string,
    mapid string,
    NODEXY1_X int,
    NODEXY1_Y int,
    NODEXY2_X int,
    NODEXY2_Y int,
    NODEXY3_X int,
    NODEXY3_Y int,
    NODEXY4_X int,
    NODEXY4_Y int,
    NODEXY5_X int,
    NODEXY5_Y int,
    NODEXY6_X int,
    NODEXY6_Y int
);

CREATE TABLE IF NOT EXISTS thea_receivedmap_genericlane_connection(
    glid string,
    mapid string,
    LANE int,
    MANEUVER bigint,
    SIGNALGROUP int
);

--------------------------------------------------
-- insert data
--------------------------------------------------
DROP TABLE IF EXISTS thea_receivedmap_tmp;
DROP TABLE IF EXISTS thea_receivedmap_genericlane_tmp;

CREATE TABLE thea_receivedmap_tmp  
    STORED AS ORC tblproperties("orc.compress"="Zlib") 
    AS SELECT reflect("java.util.UUID", "randomUUID") mapid, 
    * 
FROM thea_receivedmap_staging;

INSERT INTO TABLE thea_receivedmap_core
SELECT
    mapid,
    cast(replace(replace(METADATA.LOGUPLOADEDAT, 'T', ' '), 'Z', '') as timestamp) AS METADATALOGUPLOADEDAT,
    METADATA.MSGCNT AS METADATAMSGCNT,
    METADATA.BURSTCNT AS METADATABURSTCNT,
    METADATA.BURSTID AS METADATABURSTID,
    METADATA.HOSTVEHICLEID AS METADATAHOSTVEHICLEID,
    METADATA.LOGPSID AS METADATALOGPSID,
    METADATA.RSULIST AS METADATARSULIST,
    METADATA.RECEIVEDRSUTIMESTAMPS AS METADATARECEIVEDRSUTIMESTAMPS,
    METADATA.DATALOGID AS METADATADATALOGID,
    cast(replace(replace(METADATA.LOGGENERATEDAT, 'T', ' '), 'Z', '') as timestamp) AS METADATALOGGENERATEDAT,
    METADATA.EVENTTYPE AS METADATAEVENTTYPE,
    METADATA.DOT3.CHANNEL AS DOT3CHANNEL,
    METADATA.DOT3.PSID AS DOT3PSID,
    METADATA.DOT3.SIGNAL.RXSTRENGTH AS DOT3SIGNALRXSTRENGTH,
    METADATA.DOT3.DATARATE AS DOT3DATARATE,
    METADATA.DOT3.TIMESLOT AS DOT3TIMESLOT,
    PAYLOAD.MESSAGEFRAME.MESSAGEID AS MESSAGEID,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.MSGISSUEREVISION AS DATAMSGISSUEREVISION,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.LAYERTYPE AS DATALAYERTYPE,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.LAYERID AS DATALAYERID,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.INTERSECTIONS.INTERSECTIONGEOMETRY.ID.ID AS DATAINTERSECTIONGEOMETRYID,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.INTERSECTIONS.INTERSECTIONGEOMETRY.REVISION AS DATAINTERSECTIONGEOMETRYREVISION,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.INTERSECTIONS.INTERSECTIONGEOMETRY.REFPOINT.LAT AS DATAINTERSECTIONGEOMETRYREFPOINTLAT,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.INTERSECTIONS.INTERSECTIONGEOMETRY.REFPOINT.LONG AS DATAINTERSECTIONGEOMETRYREFPOINTLONG,
    PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.INTERSECTIONS.INTERSECTIONGEOMETRY.LANEWIDTH AS DATAINTERSECTIONGEOMETRYLANEWIDTH
FROM thea_receivedmap_tmp;

CREATE TABLE thea_receivedmap_genericlane_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
    reflect("java.util.UUID","randomUUID") glid,
    mapid,
    genericlane
FROM thea_receivedmap_tmp 
LATERAL VIEW explode(PAYLOAD.MESSAGEFRAME.VALUE.MAPDATA.INTERSECTIONS.INTERSECTIONGEOMETRY.LANESET.GENERICLANE) genericlaneArray AS genericlane;

INSERT INTO TABLE thea_receivedmap_genericlane
SELECT 
    glid,
    mapid,
    genericlane.LANEID AS LANEID,
    genericlane.INGRESSAPPROACH AS INGRESSAPPROACH,
    genericlane.MANEUVERS AS MANEUVERS,
    genericlane.LANEATTRIBUTES.DIRECTIONALUSE AS LANEATTRIBUTESDIRECTIONALUSE,
    genericlane.LANEATTRIBUTES.SHAREDWIDTH AS LANEATTRIBUTESSHAREDWIDTH,
    genericlane.LANEATTRIBUTES.LANETYPE.VEHICLE AS LANEATTRIBUTESLANETYPEVEHICLE
FROM thea_receivedmap_genericlane_tmp;

INSERT INTO TABLE thea_receivedmap_genericlane_nodexy
SELECT 
    glid,
    mapid,
    nodexy.DELTA.NODEXY1.X AS NODEXY1_X,
    nodexy.DELTA.NODEXY1.Y AS NODEXY1_Y,
    nodexy.DELTA.NODEXY2.X AS NODEXY2_X,
    nodexy.DELTA.NODEXY2.Y AS NODEXY2_Y,
    nodexy.DELTA.NODEXY3.X AS NODEXY3_X,
    nodexy.DELTA.NODEXY3.Y AS NODEXY3_Y,
    nodexy.DELTA.NODEXY4.X AS NODEXY4_X,
    nodexy.DELTA.NODEXY4.Y AS NODEXY4_Y,
    nodexy.DELTA.NODEXY5.X AS NODEXY5_X,
    nodexy.DELTA.NODEXY5.Y AS NODEXY5_Y,
    nodexy.DELTA.NODEXY6.X AS NODEXY6_X,
    nodexy.DELTA.NODEXY6.Y AS NODEXY6_Y
FROM thea_receivedmap_genericlane_tmp
LATERAL VIEW explode(genericlane.NODELIST.NODES.NODEXY) nodexyArray as nodexy;

INSERT INTO TABLE thea_receivedmap_genericlane_connection
SELECT 
    glid,
    mapid,
    connection.CONNECTINGLANE.LANE AS LANE,
    connection.CONNECTINGLANE.MANEUVER AS MANEUVER,
    connection.SIGNALGROUP AS SIGNALGROUP
FROM thea_receivedmap_genericlane_tmp
LATERAL VIEW explode(genericlane.CONNECTSTO.CONNECTION) connectionArray as connection;

--DROP temperary tables. 

DROP TABLE IF EXISTS thea_receivedmap_tmp;
DROP TABLE IF EXISTS thea_receivedmap_genericlane_tmp;
