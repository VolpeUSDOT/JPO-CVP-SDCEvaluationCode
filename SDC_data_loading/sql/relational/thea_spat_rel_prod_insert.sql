----------------------------------------------------------------------------------------------------
-- This script inserts relational data into 3 relational tables from thea_spat_staging table (which has nested JSON data).
-- A temporary table is deleted at the end of the script.
-- Relational tables:
--   thea_spat_core
--   thea_spat_intersectionstate_enabledlanes
--   thea_spat_intersectionstate_movementstate
----------------------------------------------------------------------------------------------------


DROP TABLE IF EXISTS thea_spat_tmp;

CREATE TABLE thea_spat_tmp  
	STORED AS ORC tblproperties("orc.compress"="Zlib") 
	AS SELECT reflect("java.util.UUID", "randomUUID") spatid, 
	* 
FROM thea_spat_staging;

INSERT INTO TABLE thea_spat_core
SELECT
	SPATID,
	METADATA.SCHEMAVERSION AS METADATASCHEMAVERSION,
	METADATA.RECORDGENERATEDBY AS METADATARECORDGENERATEDBY,
	METADATA.RECORDGENERATEDAT AS METADATARECORDGENERATEDAT,
	METADATA.LOGFILENAME AS METADATALOGFILENAME,
	METADATA.KIND AS METADATAKIND,
	METADATA.PSID AS METADATAPSID,
	METADATA.RSUID AS METADATARSUID,
	METADATA.EXTERNALID AS METADATAEXTERNALID,
	METADATA.DATATYPE AS METADATADATATYPE,
	PAYLOAD.DATA.SPAT.TIME_STAMP AS DATATIME_STAMP,
	PAYLOAD.DATA.SPAT.intersections.INTERSECTIONSTATE.ID.ID AS DATAINTERSECTIONSTATEID,
	PAYLOAD.DATA.SPAT.intersections.INTERSECTIONSTATE.REVISION AS DATAINTERSECTIONSTATEREVISION,
	PAYLOAD.DATA.SPAT.intersections.INTERSECTIONSTATE.STATUS AS DATAINTERSECTIONSTATESTATUS,
	PAYLOAD.DATA.SPAT.intersections.INTERSECTIONSTATE.TIME_STAMP AS DATAINTERSECTIONSTATETIME_STAMP
FROM thea_spat_tmp;

INSERT INTO TABLE thea_spat_intersectionstate_enabledlanes
SELECT
	reflect("java.util.UUID", "randomUUID") elID,
	spatID,
	laneID
FROM thea_spat_tmp
LATERAL VIEW explode(PAYLOAD.DATA.SPAT.intersections.INTERSECTIONSTATE.enabledlanes.laneID) laneArray as laneID; 		

INSERT INTO TABLE thea_spat_intersectionstate_movementstate  
SELECT
	reflect("java.util.UUID", "randomUUID") msID,
	spatID,
	ms.signalGroup AS signalGroup,
	ms.state_time_speed.MovementEvent.eventState.stop_And_Remain AS stop_And_Remain,
	ms.state_time_speed.MovementEvent.eventState.protected_Movement_Allowed AS protected_Movement_Allowed,
	ms.state_time_speed.MovementEvent.timing.minEndTime AS minEndTime,
	ms.state_time_speed.MovementEvent.timing.maxEndTime AS maxEndTime
FROM thea_spat_tmp
LATERAL VIEW explode(PAYLOAD.DATA.SPAT.intersections.INTERSECTIONSTATE.states.MovementState) msArray as ms;

DROP TABLE IF EXISTS thea_spat_tmp;