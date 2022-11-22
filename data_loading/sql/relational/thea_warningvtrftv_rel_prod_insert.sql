----------------------------------------------------------------------------------------------------
-- This script creates the relation tables if they do not exist
-- This script inserts relational data into relational tables from thea_warningvtrftv_staging table (which has nested JSON data).
-- One temporary tables are deleted at the end of the script.
-- Relational tables 
--   thea_warningvtrftv_core
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- thea_warningvtrftv_core
--------------------------------------------------
CREATE TABLE IF NOT EXISTS thea_warningvtrftv_core(
    vtrftvid string,
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
    HVBSMID string,
    HVBSMLAT int,
    HVBSMLONG int,
    HVBSMDATETIME timestamp,
    RVBSMID string,
    RVBSMLAT int,
    RVBSMLONG int,
    RVBSMDATETIME timestamp,
    METADATADRIVERWARN boolean,
    METADATAISCONTROL boolean,
    METADATAISDISABLED boolean,
    PAYLOAD string
);

--------------------------------------------------
-- INSERT INTO RELATIONAL TABLE
--------------------------------------------------
DROP TABLE thea_warningvtrftv_tmp;

CREATE TABLE thea_warningvtrftv_tmp 
STORED AS ORC tblproperties("orc.compress"="Zlib") 
AS SELECT 
    reflect("java.util.UUID", "randomUUID") vtrftvid, 
    * 
FROM thea_warningvtrftv_staging;

INSERT INTO TABLE thea_warningvtrftv_core
SELECT
    vtrftvid,
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
    METADATA.HVBSM.ID AS HVBSMID,
    METADATA.HVBSM.LAT AS HVBSMLAT,
    METADATA.HVBSM.LONG AS HVBSMLONG,
    cast(replace(replace(METADATA.HVBSM.DATETIME, 'T', ' '), 'Z', '') as timestamp) AS HVBSMDATETIME,
    METADATA.RVBSM.ID AS RVBSMID,
    METADATA.RVBSM.LAT AS RVBSMLAT,
    METADATA.RVBSM.LONG AS RVBSMLONG,
    cast(replace(replace(METADATA.RVBSM.DATETIME, 'T', ' '), 'Z', '') as timestamp) AS RVBSMDATETIME,
    METADATA.DRIVERWARN AS METADATADRIVERWARN,
    METADATA.ISCONTROL AS METADATAISCONTROL,
    METADATA.ISDISABLED AS METADATAISDISABLED,
    PAYLOAD AS PAYLOAD
FROM thea_warningvtrftv_tmp;

--DROP temperary tables. 

DROP TABLE IF EXISTS thea_warningvtrftv_tmp;
