----------------------------------------------------------------------------------------------------
-- This script creates relational tables from thea_warningfcw (which has nested JSON data).
-- One temporary tables are deleted at the end of the script.
-- Relational tables:
--   thea_warningfcw_core
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- thea_warningfcw_tmp
--------------------------------------------------
DROP TABLE IF EXISTS thea_warningfcw_tmp;
CREATE TABLE thea_warningfcw_tmp 
	STORED AS ORC tblproperties("orc.compress"="Zlib") 
	AS SELECT 
		reflect("java.util.UUID", "randomUUID") fcwid, * FROM thea_warningfcw;

--------------------------------------------------
-- thea_warningfcw_core
--------------------------------------------------
DROP TABLE IF EXISTS thea_warningfcw_core;
CREATE TABLE thea_warningfcw_core 
	STORED AS ORC tblproperties ("orc.compress" = "Zlib")
	AS SELECT 
		fcwid,
		METADATA.LOGUPLOADEDAT AS METADATALOGUPLOADEDAT,
		METADATA.MSGCNT AS METADATAMSGCNT,
		METADATA.BURSTCNT AS METADATABURSTCNT,
		METADATA.BURSTID AS METADATABURSTID,
		METADATA.HOSTVEHICLEID AS METADATAHOSTVEHICLEID,
		METADATA.LOGPSID AS METADATALOGPSID,
		METADATA.RSULIST AS METADATARSULIST,
		METADATA.RECEIVEDRSUTIMESTAMPS AS METADATARECEIVEDRSUTIMESTAMPS,
		METADATA.DATALOGID AS METADATADATALOGID,
		METADATA.LOGGENERATEDAT AS METADATALOGGENERATEDAT,
		METADATA.EVENTTYPE AS METADATAEVENTTYPE,
		METADATA.HVBSM.ID AS HVBSMID,
		METADATA.HVBSM.LAT AS HVBSMLAT,
		METADATA.HVBSM.LONG AS HVBSMLONG,
		METADATA.HVBSM.DATETIME AS HVBSMDATETIME,
		METADATA.RVBSM.ID AS RVBSMID,
		METADATA.RVBSM.LAT AS RVBSMLAT,
		METADATA.RVBSM.LONG AS RVBSMLONG,
		METADATA.RVBSM.DATETIME AS RVBSMDATETIME,
		METADATA.DRIVERWARN AS METADATADRIVERWARN,
		METADATA.ISCONTROL AS METADATAISCONTROL,
		METADATA.ISDISABLED AS METADATAISDISABLED,
		PAYLOAD AS PAYLOAD
	FROM thea_warningfcw_tmp;

--------------------------------------------------
-- drop the _tmp tables
--------------------------------------------------
DROP TABLE IF EXISTS thea_warningfcw_tmp;