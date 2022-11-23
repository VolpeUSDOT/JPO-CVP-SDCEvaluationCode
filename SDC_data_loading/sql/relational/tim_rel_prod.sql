-- MERGER of WYDOT TIM v5 and v6

DROP TABLE IF EXISTS wydot_tim_tmp;            -- temporary table, dropped at the end of the script
DROP TABLE IF EXISTS wydot_tim_metadata;       -- relational table
DROP TABLE IF EXISTS wydot_tim_snmp;           -- relational table
DROP TABLE IF EXISTS wydot_tim_broadcast;      -- relational table
DROP TABLE IF EXISTS wydot_tim_rsus;           -- relational table
DROP TABLE IF EXISTS wydot_tim_itis;           -- relational table
DROP TABLE IF EXISTS wydot_tim_region;         -- relational table
DROP TABLE IF EXISTS wydot_tim_payload;        -- relational table
--==========================================================================================
-- Part 1: LOAD TIM schema v5 data
--==========================================================================================
------------------------------------------------------------------------
-- Create wydot_tim_tmp from wydot_tim_v5
------------------------------------------------------------------------
CREATE TABLE wydot_tim_tmp 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT reflect("java.util.UUID", "randomUUID") as timid, *
	FROM   wydot_tim_v5;
------------------------------------------------------------------------
-- Create wydot_tim_metadata from wydot_tim_tmp 
------------------------------------------------------------------------
CREATE TABLE wydot_tim_metadata 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT	timid,
			CAST(NULL as string)           as metadataRequestOdeVerb,
			CAST(NULL as float)            as metadataRequestOdeVersion,
			metadata.securityResultCode    as metadataSecurityResultCode,
			metadata.recordGeneratedBy     as metadataRecordGeneratedBy,
			metadata.recordGeneratedAt     as metadataRecordGeneratedAt,
			metadata.receivedMessageDetails.locationData.elevation as metadataRecMsgDetailsLocationElevation,
			metadata.receivedMessageDetails.locationData.heading   as metadataRecMsgDetailsLocationHeading,
			metadata.receivedMessageDetails.locationData.latitude  as metadataRecMsgDetailsLocationLatitude,
			metadata.receivedMessageDetails.locationData.longitude as metadataRecMsgDetailsLocationLongitude,
			metadata.receivedMessageDetails.locationData.speed     as metadataRecMsgDetailsLocationSpeed,
			metadata.receivedMessageDetails.rxSource               as metadataRecMsgDetailsRxSource,
			metadata.schemaVersion         as metadataSchemaVersion,
			metadata.validSignature        as metadataValidSignature,
			metadata.payloadType           as metadataPayloadType,
			metadata.serialId.streamId     as metadataSerialIdStreamId,
			metadata.serialId.bundleSize   as metadataBundleSize,
			metadata.serialId.bundleId     as metadataBundleId,
			metadata.serialId.recordId     as metadataRecordId,
			metadata.serialId.serialNumber as metadataSerialNumber,
			metadata.sanitized             as metadataSanitized,
			metadata.recordType            as metadataRecordType,
			metadata.logFileName           as metadataLogFileName,
			metadata.odeReceivedAt         as metadataOdeReceivedAt
	FROM wydot_tim_tmp;
------------------------------------------------------------------------
-- NOTE: In TIM v5 metadata, SNMP, SDW, and RSUS do not exist
-- wydot_tim_snmp, wydot_tim_broadcast, and wydot_tim_rsus tables are created using TIM v6 data
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Create wydot_tim_itis from wydot_tim_tmp 
-- One-to-many relationship
------------------------------------------------------------------------
CREATE TABLE wydot_tim_itis 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT	timid,
			advisoryTable.code.item.itis as itemItis,
			advisoryTable.code.item.text as itemItisText, 
			advisoryTable.pos            as itemItisOrder
	FROM wydot_tim_tmp
	LATERAL VIEW 
	posexplode(payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.content.advisory.sequenceAdvisory)
	advisoryTable as pos, code; 
------------------------------------------------------------------------
-- Create wydot_tim_region from wydot_tim_tmp 
------------------------------------------------------------------------
CREATE TABLE wydot_tim_region 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT  timid,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.regions as regionJson
	FROM wydot_tim_tmp;
------------------------------------------------------------------------
-- Create wydot_tim_payload from wydot_tim_tmp 
------------------------------------------------------------------------
CREATE TABLE wydot_tim_payload 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT	timid,
			payload.data.MessageFrame.messageId                                                  as payloadMessageId,
			payload.data.MessageFrame.value.TravelerInformation.timeStampTravelerInformation     as payloadTimeStamp,
			payload.data.MessageFrame.value.TravelerInformation.packetID                         as payloadPacketId,
			payload.dataType                                                                     as dataType,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.url as payloadUrl,
			payload.data.MessageFrame.value.TravelerInformation.urlB                             as payloadUrlB, 
			payload.data.MessageFrame.value.TravelerInformation.msgCnt						     as payloadMsgCnt,
			substr(payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType, 3, instr(payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType, ":")-4) as payloadDataFramesFrameType,
			--payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType.advisory                  as payloadDataFramesFrameTypeAdvisory,
			--payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType.RoadSignage               as payloadDataFramesFrameTypeRoadSignage,
			--payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType.commercialSignage         as payloadDataFramesFrameTypeCommericalSignag
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.durationTime                        as payloadDataFramesDurationTime,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.sspTimRights                        as payloadDataFramesSspTimRights,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.sspMsgRights1                       as payloadDataFramesSspMsgRights1,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.sspMsgRights2                       as payloadDataFramesSspMsgRights2,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.SspLocationRights                   as payloadDataFramesSspLocationRights,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.startYear                           as payloadDataFramesStartYear,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.viewAngle          as payloadDataFramesMsgIdRoadSignIdViewAngle,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.crc                as payloadDataFramesMsgIdRoadSignCrc,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.mutcdCode.warning  as payloadDataFramesMsgIdRoadSignMutccode,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.position.elevation as payloadDataFramesMsgIdRoadSignPositionElevation,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.position.lat       as payloadDataFramesMsgIdRoadSignPositionLatitude,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.position.long      as payloadDataFramesMsgIdRoadSignPositionLongitude,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.priority                            as payloadDataFramesPriority,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.startTime                           as payloadDataFramesStartTime
	FROM wydot_tim_tmp;
--==========================================================================================
-- Part 2: LOAD TIM schema v6 data
--==========================================================================================
------------------------------------------------------------------------
-- Load TIM v6 data into wydot_tim_tmp and insert into relational tables
------------------------------------------------------------------------
DROP TABLE IF EXISTS wydot_tim_tmp;

CREATE TABLE wydot_tim_tmp 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT reflect("java.util.UUID", "randomUUID") as timid, *
	FROM   wydot_tim_v6;
------------------------------------------------------------------------
-- Insert into wydot_tim_metadata from wydot_tim_tmp 
------------------------------------------------------------------------
INSERT INTO TABLE wydot_tim_metadata
	SELECT	timid,
			metadata.request.ode.verb      as metadataRequestOdeVerb,
			metadata.request.ode.version   as metadataRequestOdeVersion,
			metadata.securityResultCode    as metadataSecurityResultCode,
			metadata.recordGeneratedBy     as metadataRecordGeneratedBy,
			metadata.recordGeneratedAt     as metadataRecordGeneratedAt,
			metadata.receivedMessageDetails.locationData.elevation as metadataRecMsgDetailsLocationElevation,
			metadata.receivedMessageDetails.locationData.heading   as metadataRecMsgDetailsLocationHeading,
			metadata.receivedMessageDetails.locationData.latitude  as metadataRecMsgDetailsLocationLatitude,
			metadata.receivedMessageDetails.locationData.longitude as metadataRecMsgDetailsLocationLongitude,
			metadata.receivedMessageDetails.locationData.speed     as metadataRecMsgDetailsLocationSpeed,
			metadata.receivedMessageDetails.rxSource               as metadataRecMsgDetailsRxSource,
			metadata.schemaVersion         as metadataSchemaVersion,
			metadata.validSignature        as metadataValidSignature,
			metadata.payloadType           as metadataPayloadType,
			metadata.serialId.streamId     as metadataSerialIdStreamId,
			metadata.serialId.bundleSize   as metadataBundleSize,
			metadata.serialId.bundleId     as metadataBundleId,
			metadata.serialId.recordId     as metadataRecordId,
			metadata.serialId.serialNumber as metadataSerialNumber,
			metadata.sanitized             as metadataSanitized,    
			metadata.recordType            as metadataRecordType,
			metadata.logFileName           as metadataLogFileName,
			metadata.odeReceivedAt         as metadataOdeReceivedAt
	FROM wydot_tim_tmp;
------------------------------------------------------------------------
-- Create wydot_tim_snmp from wydot_tim_tmp 
------------------------------------------------------------------------
CREATE TABLE wydot_tim_snmp 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT	timid,
			metadata.request.snmp.mode           as snmpMode,
			metadata.request.snmp.deliverystop   as snmpDeliverystop,
			metadata.request.snmp.rsuid          as snmpRsuid,
			metadata.request.snmp.deliverystart  as snmpDeliverystart,
			metadata.request.snmp.enable         as snmpEnable,
			metadata.request.snmp.channel        as snmpChannel,
			metadata.request.snmp.msgid          as snmpMsgidwydot,
			metadata.request.snmp.snmpInterval   as snmpInterval,
			metadata.request.snmp.status         as snmpStatus
	FROM wydot_tim_tmp
	WHERE metadata.request.snmp.rsuid is not null;
------------------------------------------------------------------------
-- Create wydot_tim_broadcast from wydot_tim_tmp 
------------------------------------------------------------------------
CREATE TABLE wydot_tim_broadcast 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	SELECT	timid,
			metadata.request.sdw.recordId                         as sdwRecordId, 
			metadata.request.sdw.serviceRegion.nwCorner.latitude  as sdwServiceRegionNwCornerLatitude, 
			metadata.request.sdw.serviceRegion.nwCorner.longitude as sdwServiceRegionNwCornerLongitude, 
			metadata.request.sdw.serviceRegion.seCorner.latitude  as sdwServiceRegionSeCornerLatitude, 
			metadata.request.sdw.serviceRegion.seCorner.longitude as sdwServiceRegionSeCornerLongitude, 
			metadata.request.sdw.ttl                              as sdwTtl
	FROM wydot_tim_tmp
	WHERE metadata.request.sdw.recordId is not null;
------------------------------------------------------------------------
-- Create wydot_tim_rsus from wydot_tim_tmp 
-- One-to-many relationship
------------------------------------------------------------------------
CREATE TABLE wydot_tim_rsus 
	STORED AS ORC tblproperties("orc.compress"="Zlib")
	AS
	select  t.timid,
			t.rCol.rsus.rsutarget  as rsuTarget,
			t.rCol.rsus.rsutimeout as rsuTimeout,
			t.rCol.rsus.rsuretries as rsuRetries,
			t.rCol.rsus.rsuindex   as rsuIndex 
	from 
	  (select * from  wydot_tim_tmp
					  LATERAL VIEW explode(metadata.request.rsus) rTable as rCol
	  ) t
	where t.rCol.rsus is not null;
------------------------------------------------------------------------
-- Insert into wydot_tim_itis from wydot_tim_tmp 
-- One-to-many relationship
------------------------------------------------------------------------
INSERT INTO TABLE wydot_tim_itis
	SELECT	timid,
			advisoryTable.code.item.itis as itemItis,
			advisoryTable.code.item.text as itemItisText,
			advisoryTable.pos            as itemItisOrder
	FROM wydot_tim_tmp
	LATERAL VIEW
	posexplode(payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.content.advisory.sequenceAdvisory)
	advisoryTable as pos, code; 
------------------------------------------------------------------------
-- Insert into wydot_tim_region from wydot_tim_tmp 
------------------------------------------------------------------------
INSERT INTO TABLE wydot_tim_region 
	SELECT	timid,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.regions as regionJson 
	FROM wydot_tim_tmp;
------------------------------------------------------------------------
-- Insert into wydot_tim_payload from wydot_tim_tmp 
------------------------------------------------------------------------
INSERT INTO TABLE wydot_tim_payload
	SELECT	timid,
			payload.data.MessageFrame.messageId                                                  as payloadMessageId,
			payload.data.MessageFrame.value.TravelerInformation.timeStampTravelerInformation     as payloadTimeStamp,
			payload.data.MessageFrame.value.TravelerInformation.packetID                         as payloadPacketId,
			payload.dataType                                                                     as dataType,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.url as payloadUrl,
			payload.data.MessageFrame.value.TravelerInformation.urlB                             as payloadUrlB, 
			payload.data.MessageFrame.value.TravelerInformation.msgCnt                           as payloadMsgCnt,
			substr(payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType, 3, instr(payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType, ":")-4) as payloadDataFramesFrameType,
			--payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType.advisory                  as payloadDataFramesFrameTypeAdvisory,
			--payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType.RoadSignage               as payloadDataFramesFrameTypeRoadSignage,
			--payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.frameType.commercialSignage         as payloadDataFramesFrameTypeCommericalSignag
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.durationTime                        as payloadDataFramesDurationTime,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.sspTimRights                        as payloadDataFramesSspTimRights,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.sspMsgRights1                       as payloadDataFramesSspMsgRights1,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.sspMsgRights2                       as payloadDataFramesSspMsgRights2,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.SspLocationRights                   as payloadDataFramesSspLocationRights,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.startYear                           as payloadDataFramesStartYear,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.viewAngle          as payloadDataFramesMsgIdRoadSignIdViewAngle,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.crc                as payloadDataFramesMsgIdRoadSignCrc,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.mutcdCode.warning  as payloadDataFramesMsgIdRoadSignMutccode,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.position.elevation as payloadDataFramesMsgIdRoadSignPositionElevation,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.position.lat       as payloadDataFramesMsgIdRoadSignPositionLatitude,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.msgId.roadSignId.position.long      as payloadDataFramesMsgIdRoadSignPositionLongitude,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.priority                            as payloadDataFramesPriority,
			payload.data.MessageFrame.value.TravelerInformation.dataFrames.TravelerDataFrame.startTime                           as payloadDataFramesStartTime
	FROM wydot_tim_tmp;
------------------------------------------------------------------------
-- Drop wydot_tim_tmp table 
------------------------------------------------------------------------
DROP TABLE IF EXISTS wydot_tim_tmp;

