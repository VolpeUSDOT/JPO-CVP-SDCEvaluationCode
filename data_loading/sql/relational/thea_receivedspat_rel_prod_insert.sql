----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from thea_receivedspat_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables 
--   thea_receivedspat_core
--   thea_receivedspat_intersectionstate_enabledlanes
--   thea_receivedspat_intersectionstate_movementstate
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create tables if needed
--------------------------------------------------
CREATE TABLE IF NOT EXISTS thea_receivedspat_core(
    spatid string,
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
    DATATIME_STAMP string,
    DATAINTERSECTIONSTATEID string,
    DATAINTERSECTIONSTATEREVISION string,
    DATAINTERSECTIONSTATESTATUS string,
    DATAINTERSECTIONSTATETIME_STAMP string
);
    
CREATE TABLE IF NOT EXISTS thea_receivedspat_intersectionstate_enabledlanes(
    elid string,
    spatid string,
    ENABLEDLANESLANEID string
);

CREATE TABLE IF NOT EXISTS thea_receivedspat_intersectionstate_movementstate(
    msid string,
    spatid string,
    MOVEMENTSTATESIGNALGROUP string,
    MOVEMENTSTATEEVENTSTATE string,
    MOVEMENTSTATEMINENDTIME string,
    MOVEMENTSTATEMAXENDTIME string
);

--------------------------------------------------
-- insert data
--------------------------------------------------
DROP TABLE IF EXISTS thea_receivedspat_tmp;

CREATE TABLE thea_receivedspat_tmp  
    STORED AS ORC tblproperties("orc.compress"="Zlib") 
    AS SELECT reflect("java.util.UUID", "randomUUID") spatid, 
    * 
FROM thea_receivedspat_staging;

INSERT INTO TABLE thea_receivedspat_core
SELECT
    spatid,
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
    PAYLOAD.MESSAGEFRAME.VALUE.SPAT.TIME_STAMP AS DATATIME_STAMP,
    PAYLOAD.MESSAGEFRAME.VALUE.SPAT.INTERSECTIONS.INTERSECTIONSTATE.ID.ID AS DATAINTERSECTIONSTATEID,
    PAYLOAD.MESSAGEFRAME.VALUE.SPAT.INTERSECTIONS.INTERSECTIONSTATE.REVISION AS DATAINTERSECTIONSTATEREVISION,
    PAYLOAD.MESSAGEFRAME.VALUE.SPAT.INTERSECTIONS.INTERSECTIONSTATE.STATUS AS DATAINTERSECTIONSTATESTATUS,
    PAYLOAD.MESSAGEFRAME.VALUE.SPAT.INTERSECTIONS.INTERSECTIONSTATE.TIME_STAMP AS DATAINTERSECTIONSTATETIME_STAMP
FROM thea_receivedspat_tmp;

INSERT INTO TABLE thea_receivedspat_intersectionstate_enabledlanes
SELECT 
    reflect("java.util.UUID", "randomUUID") elid,
    spatid,
    ENABLEDLANESLANEID
FROM thea_receivedspat_tmp
LATERAL VIEW explode(PAYLOAD.MESSAGEFRAME.VALUE.SPAT.INTERSECTIONS.INTERSECTIONSTATE.ENABLEDLANES.LANEID) laneArray as ENABLEDLANESLANEID;

INSERT INTO TABLE thea_receivedspat_intersectionstate_movementstate
SELECT 
    reflect("java.util.UUID", "randomUUID") msid,
    spatid,
    MS.SIGNALGROUP AS MOVEMENTSTATESIGNALGROUP,
    MS.STATE_TIME_SPEED.MOVEMENTEVENT.EVENTSTATE AS MOVEMENTSTATEEVENTSTATE,
    MS.STATE_TIME_SPEED.MOVEMENTEVENT.TIMING.MINENDTIME AS MOVEMENTSTATEMINENDTIME,
    MS.STATE_TIME_SPEED.MOVEMENTEVENT.TIMING.MAXENDTIME AS MOVEMENTSTATEMAXENDTIME
FROM thea_receivedspat_tmp
LATERAL VIEW explode(PAYLOAD.MESSAGEFRAME.VALUE.SPAT.INTERSECTIONS.INTERSECTIONSTATE.STATES.MOVEMENTSTATE) msArray as MS;

--DROP temperary tables. 

DROP TABLE IF EXISTS thea_receivedspat_tmp;