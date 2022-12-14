----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from thea_bsm_v5_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables:
--   thea_bsm_core
--   thea_bsm_partii
--   thea_bsm_partii_crumbdata
----------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS thea_bsm_tmp;
DROP TABLE IF EXISTS thea_bsm_partii_tmp;

CREATE TABLE thea_bsm_tmp 
STORED AS ORC tblproperties("orc.compress"="Zlib") 
AS SELECT 
	reflect("java.util.UUID", "randomUUID") bsmid, 
	* 
FROM thea_bsm_staging_v5;

INSERT INTO TABLE thea_bsm_core
SELECT
	bsmid,
	METADATA.SCHEMAVERSION AS METADATASCHEMAVERSION,
	METADATA.RECORDGENERATEDBY AS METADATARECORDGENERATEDBY,
	METADATA.RECORDGENERATEDAT AS METADATARECORDGENERATEDAT,
	METADATA.KIND AS METADATAKIND,
	METADATA.BSMSOURCE AS METADATABSMSOURCE,
	METADATA.PSID AS METADATAPSID,
	METADATA.RSUID AS METADATARSUID,
	METADATA.EXTERNALID AS METADATAEXTERNALID,
	METADATA.DATATYPE AS METADATADATATYPE,
	METADATA.LOGFILENAME AS METADATALOGFILENAME,
	PAYLOAD.DATA.COREDATA.MSGCNT AS COREDATAMSGCNT,
	PAYLOAD.DATA.COREDATA.ID AS COREDATAID,
	PAYLOAD.DATA.COREDATA.SECMARK AS COREDATASECMARK,
	PAYLOAD.DATA.COREDATA.LAT AS COREDATALAT,
	PAYLOAD.DATA.COREDATA.LONG AS COREDATALONG,
	PAYLOAD.DATA.COREDATA.ELEV AS COREDATAELEV,
	PAYLOAD.DATA.COREDATA.ACCURACY.SEMIMAJOR AS COREDATAACCURACYSEMIMAJOR,
	PAYLOAD.DATA.COREDATA.ACCURACY.SEMIMINOR AS COREDATAACCURACYSEMIMINOR,
	PAYLOAD.DATA.COREDATA.ACCURACY.ORIENTATION AS COREDATAACCURACYORIENTATION,
	PAYLOAD.DATA.COREDATA.TRANSMISSION.FORWARDGEARS AS COREDATATRANSMISSIONFORWARDGEARS,
	PAYLOAD.DATA.COREDATA.SPEED AS COREDATASPEED,
	PAYLOAD.DATA.COREDATA.HEADING AS COREDATAHEADING,
	PAYLOAD.DATA.COREDATA.ANGLE AS COREDATAANGLE,
	PAYLOAD.DATA.COREDATA.ACCELSET.LONG AS COREDATAACCELSETLONG,
	PAYLOAD.DATA.COREDATA.ACCELSET.LAT AS COREDATAACCELSETLAT,
	PAYLOAD.DATA.COREDATA.ACCELSET.VERT AS COREDATAACCELSETVERT,
	PAYLOAD.DATA.COREDATA.ACCELSET.YAW AS COREDATAACCELSETYAW,
	PAYLOAD.DATA.COREDATA.BRAKES.WHEELBRAKES AS COREDATABRAKESWHEELBRAKES,
	PAYLOAD.DATA.COREDATA.BRAKES.TRACTION.UNAVAILABLE AS COREDATABRAKESTRACTIONUNAVAILABLE,
	PAYLOAD.DATA.COREDATA.BRAKES.ABS.UNAVAILABLE AS COREDATABRAKESABSUNAVAILABLE,
	PAYLOAD.DATA.COREDATA.BRAKES.SCS.UNAVAILABLE AS COREDATABRAKESSCSUNAVAILABLE,
	PAYLOAD.DATA.COREDATA.BRAKES.BRAKEBOOST.UNAVAILABLE AS COREDATABRAKESBRAKEBOOSTUNAVAILABLE,
	PAYLOAD.DATA.COREDATA.BRAKES.AUXBRAKES.UNAVAILABLE AS COREDATABRAKESAUXBRAKESUNAVAILABLE,
	PAYLOAD.DATA.COREDATA.SIZE.WIDTH AS COREDATASIZEWIDTH,
	PAYLOAD.DATA.COREDATA.SIZE.LENGTH AS COREDATASIZELENGTH
FROM thea_bsm_tmp;

-- CREATE bsm part ii tmp

CREATE TABLE thea_bsm_partii_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
	reflect("java.util.UUID","randomUUID") partiiid,
	bsmid,
	partii
FROM thea_bsm_tmp 
LATERAL VIEW explode(PAYLOAD.DATA.PARTII.SEQUENCE) sequenceArray AS partii;

-- insert part ii data into thea bsm part ii table

INSERT INTO TABLE thea_bsm_partii
SELECT 
	partiiid,
	bsmid,
	partii.partiiid AS id,
	partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.CLASSIFICATION AS SUPPLEMENTALVEHICLEEXTENSIONSCLASSIFICATION,
	partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.CLASSDETAILS.ROLE.BASICVEHICLE AS SUPPLEMENTALVEHICLEEXTENSIONSCLASSDETAILSROLEBASICVEHICLE,
	partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.CLASSDETAILS.HPMSTYPE.CAR AS SUPPLEMENTALVEHICLEEXTENSIONSCLASSDETAILSHPMSTYPECAR,
	partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.HEIGHT AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATAHEIGHT,
	partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.BUMPERS.FRONT AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATABUMPERSFRONT,
	partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.BUMPERS.REAR AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATABUMPERSREAR,
	partii.PARTIIVALUE.SUPPLEMENTALVEHICLEEXTENSIONS.VEHICLEDATA.MASS AS SUPPLEMENTALVEHICLEEXTENSIONSVEHICLEDATAMASS
FROM thea_bsm_partii_tmp;

-- Insert crumb data into bsm part ii crumb data

INSERT INTO TABLE thea_bsm_partii_crumbdata
SELECT
	partiiid,
	bsmid,
	php.LATOFFSET AS LATOFFSET,
	php.LONOFFSET AS LONOFFSET,
	php.ELEVATIONOFFSET AS ELEVATIONOFFSET,
	php.TIMEOFFSET AS TIMEOFFSET
FROM thea_bsm_partii_tmp
LATERAL VIEW explode (partii.PARTIIVALUE.VEHICLESAFETYEXTENSIONS.PATHHISTORY.CRUMBDATA.pathhistorypoint) phpArray AS php;

--DROP temperary tables. 

DROP TABLE IF EXISTS thea_bsm_tmp;
DROP TABLE IF EXISTS thea_bsm_partii_tmp;