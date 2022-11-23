----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from nyc_map_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables:
--   nyc_map_core
--   nyc_map_intersections
--   nyc_map_intersections_speedlimits
--   nyc_map_intersections_laneset
--   nyc_map_intersections_laneset_nodes
--   nyc_map_intersections_laneset_connectsto
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create tables if needed
--------------------------------------------------
CREATE TABLE IF NOT EXISTS nyc_map_core(
    mapid string,
    EVENTID string,
    EVENTTYPE string,
    SEQNUM int,
    MAPRECACTMSGHEADERMYRFLEVEL int,
    MAPRECACTMSGHEADERAUTHENTICATED boolean,
    MAPRECACTMAPMSGLAYERTYPE string,
    MAPRECACTMAPMSGLAYERID int
);
    
CREATE TABLE IF NOT EXISTS nyc_map_intersections(
    interid string,
    mapid string,
    INTERSECTIONID string,
    INTERSECTIONREFPOINTX_M double,
    INTERSECTIONREFPOINTY_M double,
    INTERSECTIONREFPOINTZ_M double,
    INTERSECTIONLANEWIDTH int
);

CREATE TABLE IF NOT EXISTS nyc_map_intersections_speedlimits(
    interid string,
    mapid string,
    SPEEDLIMITTYPE string,
    SPEEDLIMITSPEED_MPS double
);

CREATE TABLE IF NOT EXISTS nyc_map_intersections_laneset(
    laneid string,
    interid string,
    mapid string,
    LANESETLANEID int,
    LANESETINGRESSAPPROACH int,
    LANESETLANEATTRIBUTESDIRECTIONALUSE string,
    LANESETLANEATTRIBUTESSHAREDWIDTH string,
    LANESETLANEATTRIBUTESLANETYPEBIKELANE string,
    LANESETMANEUVERS string
);

CREATE TABLE IF NOT EXISTS nyc_map_intersections_laneset_nodes(
    laneid string,
    interid string,
    mapid string,
    DELTANODEXY1_X int,
    DELTANODEXY1_Y int,
    DELTANODEXY2_X int,
    DELTANODEXY2_Y int,
    DELTANODEXY3_X int,
    DELTANODEXY3_Y int,
    DELTANODEXY4_X int,
    DELTANODEXY4_Y int,
    DELTANODEXY5_X int,
    DELTANODEXY5_Y int,
    DELTANODEXY6_X int,
    DELTANODEXY6_Y int,
    ATTRIBUTESDWIDTH int,
    ATTRIBUTESDELEVATION int
);

CREATE TABLE IF NOT EXISTS nyc_map_intersections_laneset_connectsto(
    laneid string,
    interid string,
    mapid string,
    CONNECTINGLANELANE int,
    CONNECTINGLANEMANEUVER string,
    SIGNALGROUP int,
    CONNECTIONID int
);

--------------------------------------------------
-- insert data nyc_map_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_map_tmp;

CREATE TABLE nyc_map_tmp  
    STORED AS ORC tblproperties("orc.compress"="Zlib") 
    AS SELECT reflect("java.util.UUID", "randomUUID") mapid, 
    * 
FROM nyc_map_staging;

INSERT INTO TABLE nyc_map_core
SELECT
    mapid,
    EVENTID AS EVENTID,
    EVENTTYPE AS EVENTTYPE,
    SEQNUM AS SEQNUM,
    MAPRECACT.MSGHEADER.MYRFLEVEL AS MAPRECACTMSGHEADERMYRFLEVEL,
    MAPRECACT.MSGHEADER.AUTHENTICATED AS MAPRECACTMSGHEADERAUTHENTICATED,
    MAPRECACT.MAPMSG.LAYERTYPE AS MAPRECACTMAPMSGLAYERTYPE,
    MAPRECACT.MAPMSG.LAYERID AS MAPRECACTMAPMSGLAYERID
FROM nyc_map_tmp;

--------------------------------------------------
-- insert data nyc_map_intersections_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_map_intersections_tmp;

CREATE TABLE nyc_map_intersections_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
    reflect("java.util.UUID","randomUUID") interid,
    mapid,
    intersections
FROM nyc_map_tmp 
LATERAL VIEW explode(MAPRECACT.MAPMSG.INTERSECTIONS) intersectionsArray AS intersections;

INSERT INTO TABLE nyc_map_intersections
SELECT 
    interid,
    mapid,
    intersections.ID.ID AS INTERSECTIONID,
    intersections.REFPOINT.X_M AS INTERSECTIONREFPOINTX_M,
    intersections.REFPOINT.Y_M AS INTERSECTIONREFPOINTY_M,
    intersections.REFPOINT.Z_M AS INTERSECTIONREFPOINTZ_M,
    intersections.LANEWIDTH AS INTERSECTIONLANEWIDTH
FROM nyc_map_intersections_tmp;

INSERT INTO TABLE nyc_map_intersections_speedlimits
SELECT 
    interid,
    mapid,
    speedlimits.TYPE AS SPEEDLIMITTYPE,
    speedlimits.SPEED_MPS AS SPEEDLIMITSPEED_MPS
FROM nyc_map_intersections_tmp
LATERAL VIEW explode(intersections.SPEEDLIMITS) speedlimitsArray as speedlimits;

--------------------------------------------------
-- insert data nyc_map_intersections_laneset_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_map_intersections_laneset_tmp;

CREATE TABLE nyc_map_intersections_laneset_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
    reflect("java.util.UUID","randomUUID") laneid,
    interid,
    mapid,
    laneset
FROM nyc_map_intersections_tmp 
LATERAL VIEW explode(intersections.LANESET) lanesetArray AS laneset;

INSERT INTO TABLE nyc_map_intersections_laneset
SELECT 
    laneid,
    interid,
    mapid,
    laneset.LANEID AS LANESETLANEID,
    laneset.INGRESSAPPROACH AS LANESETINGRESSAPPROACH,
    laneset.LANEATTRIBUTES.DIRECTIONALUSE AS LANESETLANEATTRIBUTESDIRECTIONALUSE,
    laneset.LANEATTRIBUTES.SHAREDWIDTH AS LANESETLANEATTRIBUTESSHAREDWIDTH,
    laneset.LANEATTRIBUTES.LANETYPE.BIKELANE AS LANESETLANEATTRIBUTESLANETYPEBIKELANE,
    laneset.MANEUVERS AS LANESETMANEUVERS
FROM nyc_map_intersections_laneset_tmp;

INSERT INTO TABLE nyc_map_intersections_laneset_nodes
SELECT 
    laneid,
    interid,
    mapid,
    nodes.DELTA.NODEXY1.X AS DELTANODEXY1_X,
    nodes.DELTA.NODEXY1.Y AS DELTANODEXY1_Y,
    nodes.DELTA.NODEXY2.X AS DELTANODEXY2_X,
    nodes.DELTA.NODEXY2.Y AS DELTANODEXY2_Y,
    nodes.DELTA.NODEXY3.X AS DELTANODEXY3_X,
    nodes.DELTA.NODEXY3.Y AS DELTANODEXY3_Y,
    nodes.DELTA.NODEXY4.X AS DELTANODEXY4_X,
    nodes.DELTA.NODEXY4.Y AS DELTANODEXY4_Y,
    nodes.DELTA.NODEXY5.X AS DELTANODEXY5_X,
    nodes.DELTA.NODEXY5.Y AS DELTANODEXY5_Y,
    nodes.DELTA.NODEXY6.X AS DELTANODEXY6_X,
    nodes.DELTA.NODEXY6.Y AS DELTANODEXY6_Y,
    nodes.ATTRIBUTES.DWIDTH AS ATTRIBUTESDWIDTH,
    nodes.ATTRIBUTES.DELEVATION AS ATTRIBUTESDELEVATION
    
FROM nyc_map_intersections_laneset_tmp
LATERAL VIEW explode(laneset.NODELIST.NODES) nodesArray as nodes;

INSERT INTO TABLE nyc_map_intersections_laneset_connectsto
SELECT 
    laneid,
    interid,
    mapid,
    connectsto.CONNECTINGLANE.LANE AS CONNECTINGLANELANE,
    connectsto.CONNECTINGLANE.MANEUVER AS CONNECTINGLANEMANEUVER,
    connectsto.SIGNALGROUP AS SIGNALGROUP,
    connectsto.CONNECTIONID AS CONNECTIONID
FROM nyc_map_intersections_laneset_tmp
LATERAL VIEW explode(laneset.CONNECTSTO) connectstoArray as connectsto;

--DROP temperary tables. 

DROP TABLE IF EXISTS nyc_map_tmp;
DROP TABLE IF EXISTS nyc_map_genericlane_tmp;
DROP TABLE IF EXISTS nyc_map_intersections_laneset_tmp;
