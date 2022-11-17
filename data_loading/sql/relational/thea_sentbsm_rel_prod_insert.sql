----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from thea_sentbsm_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables 
--   thea_sentbsm_core
--   thea_sentbsm_partii
--   thea_sentbsm_partii_crumbdata
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create tables
--------------------------------------------------
CREATE TABLE IF NOT EXISTS thea_sentbsm_core(
    bsmid string,
    METADATALOGUPLOADEDAT timestamp,
    METADATAMSGCNT int,
    METADATABURSTCNT int,
    METADATABURSTID bigint,
    METADATAHOSTVEHICLEID string,
    METADATALOGPSID string,
    METADATARSULIST string,
    METADATARECEIVEDRSUTIMESTAMPS string,
    METADATADATALOGID string,
    METADATALOGGENERATEDAT timestamp,
    METADATAEVENTTYPE string,
    DOT3CHANNEL int,
    DOT3PSID string,
    DOT3SIGNALRXSTRENGTH int,
    DOT3DATARATE int,
    DOT3TIMESLOT int,
    MESSAGEFRAMEMESSAGEID int,
    COREDATAMSGCOUNT int,
    COREDATAID string,
    COREDATASECMARK int,
    COREDATALAT int,
    COREDATALONG int,
    COREDATAELEV int,
    COREDATAACCURACYSEMIMAJOR int,
    COREDATAACCURACYSEMIMINOR int,
    COREDATAACCURACYORIENTATION int,
    COREDATATRANSMISSION string,
    COREDATASPEED int,
    COREDATAHEADING int,
    COREDATAANGLE int,
    COREDATAACCELSETLONG int,
    COREDATAACCELSETLAT int,
    COREDATAACCELSETVERT int,
    COREDATAACCELSETYAW int,
    COREDATABRAKESWHEELBRAKES string,
    COREDATABRAKESTRACTION string,
    COREDATABRAKESABS string,
    COREDATABRAKESSCS string,
    COREDATABRAKESBRAKEBOOST string,
    COREDATABRAKESAUXBRAKES string,
    COREDATASIZEWIDTH int,
    COREDATASIZELENGTH int
);
    
CREATE TABLE IF NOT EXISTS thea_sentbsm_partii(
    partiiid string,
    bsmid string,
    id int,
    SUPPLEMENTALVEHICLEEXTENSIONSCLASSIFICATION int,
    SUPPLEMENTALVEHICLEEXTENSIONSCLASSDETAILSROLE string,
    SUPPLEMENTALVEHICLEEXTENSIONSCLASSDETAILSHPMSTYPE string,
    SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATAHEIGHT int,
    SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATABUMPERSFRONT int,
    SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATABUMPERSREAR int,
    SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATAMASS int
);

CREATE TABLE IF NOT EXISTS thea_sentbsm_partii_crumbdata(
    partiiid string,
    bsmid string,
    LATOFFSET int,
    LONOFFSET int,
    ELEVATIONOFFSET int,
    TIMEOFFSET int
);

--------------------------------------------------
-- drop the _tmp tables
--------------------------------------------------
DROP TABLE IF EXISTS thea_sentbsm_tmp;
DROP TABLE IF EXISTS thea_sentbsm_partii_tmp;

CREATE TABLE thea_sentbsm_tmp 
STORED AS ORC tblproperties("orc.compress"="Zlib") 
AS SELECT 
    reflect("java.util.UUID", "randomUUID") bsmid, 
    * 
FROM thea_sentbsm_staging;

INSERT INTO TABLE thea_sentbsm_core
SELECT
    bsmid,
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
    PAYLOAD.MESSAGEFRAME.MESSAGEID AS MESSAGEFRAMEMESSAGEID,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.MSGCNT AS COREDATAMSGCOUNT,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ID AS COREDATAID,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.SECMARK AS COREDATASECMARK,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.LAT AS COREDATALAT,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.LONG AS COREDATALONG,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ELEV AS COREDATAELEV,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ACCURACY.SEMIMAJOR AS COREDATAACCURACYSEMIMAJOR,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ACCURACY.SEMIMINOR AS COREDATAACCURACYSEMIMINOR,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ACCURACY.ORIENTATION AS COREDATAACCURACYORIENTATION,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.TRANSMISSION AS COREDATATRANSMISSION,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.SPEED AS COREDATASPEED,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.HEADING AS COREDATAHEADING,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ANGLE AS COREDATAANGLE,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ACCELSET.LONG AS COREDATAACCELSETLONG,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ACCELSET.LAT AS COREDATAACCELSETLAT,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ACCELSET.VERT AS COREDATAACCELSETVERT,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.ACCELSET.YAW AS COREDATAACCELSETYAW,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.BRAKES.WHEELBRAKES AS COREDATABRAKESWHEELBRAKES,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.BRAKES.TRACTION AS COREDATABRAKESTRACTION,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.BRAKES.ABS AS COREDATABRAKESABS,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.BRAKES.SCS AS COREDATABRAKESSCS,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.BRAKES.BRAKEBOOST AS COREDATABRAKESBRAKEBOOST,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.BRAKES.AUXBRAKES AS COREDATABRAKESAUXBRAKES,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.SIZE.WIDTH AS COREDATASIZEWIDTH,
    PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.COREDATA.SIZE.LENGTH AS COREDATASIZELENGTH
FROM thea_sentbsm_tmp;

-- CREATE sentbsm part ii tmp

CREATE TABLE thea_sentbsm_partii_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
    reflect("java.util.UUID","randomUUID") partiiid,
    bsmid,
    partii
FROM thea_sentbsm_tmp 
LATERAL VIEW explode(PAYLOAD.MESSAGEFRAME.VALUE.BASICSAFETYMESSAGE.PARTII.SEQUENCE) sequenceArray AS partii;

-- insert part ii data into thea sentbsm part ii table

INSERT INTO TABLE thea_sentbsm_partii
SELECT 
    partiiid,
    bsmid,
    partii.partiiid AS id,
    partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.CLASSIFICATION AS SUPPLEMENTALVEHICLEEXTENSIONSCLASSIFICATION,
    partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.CLASSDETAILS.ROLE AS SUPPLEMENTALVEHICLEEXTENSIONSCLASSDETAILSROLE,
    partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.CLASSDETAILS.HPMSTYPE AS SUPPLEMENTALVEHICLEEXTENSIONSCLASSDETAILSHPMSTYPE,
    partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.HEIGHT AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATAHEIGHT,
    partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.BUMPERS.FRONT AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATABUMPERSFRONT,
    partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.BUMPERS.REAR AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATABUMPERSREAR,
    partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.MASS AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATAMASS
FROM thea_sentbsm_partii_tmp;

-- Insert crumb data into sentbsm part ii crumb data

INSERT INTO TABLE thea_sentbsm_partii_crumbdata
SELECT
    partiiid,
    bsmid,
    php.LATOFFSET AS LATOFFSET,
    php.LONOFFSET AS LONOFFSET,
    php.ELEVATIONOFFSET AS ELEVATIONOFFSET,
    php.TIMEOFFSET AS TIMEOFFSET
FROM thea_sentbsm_partii_tmp
LATERAL VIEW explode (partii.PARTIIVALUE.VEHICLESAFETYEXTENSIONS.PATHHISTORY.CRUMBDATA.pathhistorypoint) phpArray AS php;

--DROP temperary tables. 

DROP TABLE IF EXISTS thea_sentbsm_tmp;
DROP TABLE IF EXISTS thea_sentbsm_partii_tmp;