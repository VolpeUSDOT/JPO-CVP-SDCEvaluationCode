----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from thea_receivedpsm_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables 
--   thea_receivedpsm_core
--   thea_receivedpsm_psm
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create tables
--------------------------------------------------
CREATE TABLE IF NOT EXISTS thea_receivedpsm_core(
    psmid string,
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
    DATABASICTYPE string,
    DATASECMARK int,
    DATAMSGCNT int,
    DATAID string,
    DATAPOSITIONLAT int,
    DATAPOSITIONLONG int,
    DATAACCURACYSEMIMAJOR int,
    DATAACCURACYSEMIMINOR int,
    DATAACCURACYORIENTATION int,
    DATASPEED int,
    DATAHEADING int,
    DATAPATHPREDICTIONRADIUSOFCURVE int,
    DATAPATHPREDICTIONCONFIDENCE int
);

--------------------------------------------------
-- drop the _tmp tables
--------------------------------------------------
DROP TABLE IF EXISTS thea_receivedpsm_tmp;

CREATE TABLE thea_receivedpsm_tmp 
STORED AS ORC tblproperties("orc.compress"="Zlib") 
AS SELECT 
    reflect("java.util.UUID", "randomUUID") psmid, 
    * 
FROM thea_receivedpsm_staging;

INSERT INTO TABLE thea_receivedpsm_core
SELECT
    psmid,
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
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.BASICTYPE AS DATABASICTYPE,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.SECMARK AS DATASECMARK,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.MSGCNT AS DATAMSGCNT,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.ID AS DATAID,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.POSITION.LAT AS DATAPOSITIONLAT,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.POSITION.LONG AS DATAPOSITIONLONG,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.ACCURACY.SEMIMAJOR AS DATAACCURACYSEMIMAJOR,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.ACCURACY.SEMIMINOR AS DATAACCURACYSEMIMINOR,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.ACCURACY.ORIENTATION AS DATAACCURACYORIENTATION,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.SPEED AS DATASPEED,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.HEADING AS DATAHEADING,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.PATHPREDICTION.RADIUSOFCURVE AS DATAPATHPREDICTIONRADIUSOFCURVE,
    PAYLOAD.MESSAGEFRAME.VALUE.PERSONALSAFETYMESSAGE.PATHPREDICTION.CONFIDENCE AS DATAPATHPREDICTIONCONFIDENCE
FROM thea_receivedpsm_tmp;

--DROP temperary tables. 

DROP TABLE IF EXISTS thea_receivedpsm_tmp;