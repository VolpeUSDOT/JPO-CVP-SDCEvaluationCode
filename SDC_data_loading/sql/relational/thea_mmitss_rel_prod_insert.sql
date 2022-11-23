----------------------------------------------------------------------------------------------------
-- Insert of THEA MMITSS data into the following relational tables from thea_mmitss_staging table
--   thea_mmitss_metadata
--   thea_mmitss_queuelen
--   thea_mmitss_trafperf
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create a temp table, thea_mmitss_tmp
--------------------------------------------------
DROP TABLE IF EXISTS thea_mmitss_tmp;

CREATE TABLE thea_mmitss_tmp 
	STORED AS ORC tblproperties("orc.compress"="Zlib") 
	AS SELECT reflect("java.util.UUID", "randomUUID") as mmitssid, *
	     FROM thea_mmitss_staging;
--------------------------------------------------
-- thea_mmitss_metadata
--------------------------------------------------
INSERT INTO TABLE thea_mmitss_metadata
	SELECT
		mmitssid,
		METADATA.DATATYPE          AS METADATADATATYPE,
		METADATA.KIND              AS METADATAKIND,
		METADATA.LOGFILENAME       AS METADATALOGFILENAME,
		METADATA.PSID              AS METADATAPSID,
		METADATA.RECORDGENERATEDAT AS METADATARECORDGENERATEDAT,
		METADATA.RECORDGENERATEDBY AS METADATARECORDGENERATEDBY,
		METADATA.RSUID             AS METADATARSUID,
		METADATA.SCHEMAVERSION     AS METADATASCHEMAVERSION
	FROM thea_mmitss_tmp;
--------------------------------------------------
-- thea_mmitss_queuelen
--------------------------------------------------
INSERT INTO TABLE thea_mmitss_queuelen
	SELECT 
        mmitssid,
		q.approach      as approach,
		q.lane          as lane,
		q.queue_count   as queueCount,
		q.queue_len     as queueLen,
		q.vehicle_count as vehicleCount
	FROM thea_mmitss_tmp 
	LATERAL VIEW explode(PAYLOAD.queuelen) qArray AS q;
--------------------------------------------------
-- thea_mmitss_trafperf
--------------------------------------------------
INSERT INTO TABLE thea_mmitss_trafperf
	SELECT 
        mmitssid,
		t.delay       as delay,
		t.throughput  as throughput,
		t.num_stops   as numStops,
		t.movement    as movement,
		t.travel_time as travelTime
	FROM thea_mmitss_tmp 
	LATERAL VIEW explode(PAYLOAD.trafperf) tArray AS t;
--------------------------------------------------
-- drop the temp table
--------------------------------------------------
DROP TABLE IF EXISTS thea_mmitss_tmp;
