DROP TABLE IF EXISTS wydot_alert_tmp;

CREATE TABLE wydot_alert_tmp STORED
AS
ORC tblproperties("orc.compress"="Zlib")
AS
SELECT
    *
FROM wydot_alert_v5_staging;

INSERT INTO TABLE wydot_alert_core 
SELECT
    metadata.logFileName as metadataLogFileName,
    metadata.recordType as metadataRecordType,
    metadata.receivedMessageDetails.locationData.latitude as metadataReceivedMessageDetailsLocationDataLatitude,
    metadata.receivedMessageDetails.locationData.longitude as metadataReceivedMessageDetailsLocationDataLongitude,
    metadata.receivedMessageDetails.locationData.elevation as metadataReceivedMessageDetailsLocationDataElevation,
    metadata.receivedMessageDetails.locationData.speed as metadataReceivedMessageDetailsLocationDataSpeed,
    metadata.receivedMessageDetails.locationData.heading as metadataReceivedMessageDetailsLocationDataHeading,
    metadata.payloadType as metadataPayloadType,
    metadata.serialId.streamId as metadataSerialIdStreamId,
    metadata.serialId.bundleSize as metadataSerialIdBundleSize,
    metadata.serialId.bundleId as metadataSerialIdBundleId,
    metadata.serialId.recordId as metadataSerialIdRecordId,
    metadata.serialId.serialNumber as metadataSerialIdSerialNumber,
    metadata.odeReceivedAt as metadataOdeReceivedAt,
    metadata.schemaVersion as metadataSchemaVersion,
    metadata.recordGeneratedAt as metadataRecordGeneratedAt,
    metadata.recordGeneratedBy as metadataRecordGeneratedBy,
    metadata.sanitized as metadataSanitized,
    payload.alert as payloadAlert
FROM wydot_alert_tmp;

DROP TABLE IF EXISTS wydot_alert_tmp
