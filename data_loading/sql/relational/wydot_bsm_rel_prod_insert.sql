-- INSERT releational data into relational tables

-- LOAD BSM v4 data
DROP TABLE IF EXISTS wydot_bsm_tmp;
DROP TABLE IF EXISTS wydot_bsm_partii_tmp;

-- LOAD BSM v5 data into tmp and extend into core

CREATE TABLE wydot_bsm_tmp STORED
AS
ORC tblproperties ("orc.compress" = "Zlib")
AS
SELECT reflect("java.util.UUID","randomUUID") bsmid,
       *
FROM wydot_bsm_staging_v5;

INSERT INTO TABLE wydot_bsm_core
SELECT bsmid,
       metadata.bsmSource AS metadataBsmSource,
       metadata.logFileName AS metadataLogFileName,
       metadata.recordType AS metadataRecordType,
       metadata.payloadType AS metadataPayloadType,
       metadata.serialId.streamId AS metadataStreamId,
       metadata.serialId.bundleSize AS metadataBundleSize,
       metadata.serialId.bundleId AS metadataBundleId,
       metadata.serialId.recordId AS metadataRecordId,
       metadata.serialId.serialNumber AS metadataSerialNumber,
       metadata.odeReceivedAt AS metadataOdeReceivedAt,
       metadata.schemaVersion AS metadataSchemaVersion,
       metadata.recordGeneratedAt AS metadataRecordGeneratedAt,
       metadata.recordGeneratedBy AS metadataRecordGeneratedBy,
       NULL AS metadataValidSignature,
       metadata.securityResultCode AS metadataSecurityResultCode,
       CAST(metadata.receivedMessageDetails.locationData.latitude AS FLOAT) AS metadataReceivedMessageDetailsLocationDataLatitude,
       CAST(metadata.receivedMessageDetails.locationData.longitude AS FLOAT) AS metadataReceivedMessageDetailsLocationDataLongitude,
       CAST(metadata.receivedMessageDetails.locationData.elevation AS FLOAT) AS metadataReceivedMessageDetailsLocationDataElevation,
       CAST(metadata.receivedMessageDetails.locationData.speed AS FLOAT) AS metadataReceivedMessageDetailsLocationDataSpeed,
       CAST(metadata.receivedMessageDetails.locationData.heading AS FLOAT) AS metadataReceivedMessageDetailsLocationDataHeading,
       metadata.receivedMessageDetails.rxSource AS metadataReceivedMessageDetailsRxSource,
       metadata.sanitized AS metadataSanitized,
       payload.data.coredata.msgCnt AS coredataMsgCnt,
       payload.data.coredata.id AS coredataId,
       payload.data.coredata.secMark AS coredatasecMark,
       CAST(payload.data.coredata.position.latitude AS FLOAT) AS coredataLatitude,
       CAST(payload.data.coredata.position.longitude AS FLOAT) AS coredataLongitude,
       CAST(payload.data.coredata.position.elevation AS FLOAT) AS coredataElevation,
       CAST(payload.data.coredata.accelset.accelYaw AS FLOAT) AS coredataAccelYaw,
       CAST(payload.data.coredata.accelset.accelLat AS FLOAT) AS coredataAccelLat,
       CAST(payload.data.coredata.accelset.accelLong AS FLOAT) AS coredataAccelLong,
       CAST(payload.data.coredata.accelset.accelVert AS FLOAT) AS coredataAccelVert,
       CAST(payload.data.coredata.accuracy.semiMajor AS FLOAT) AS coredataAccuracySemiMajor,
       CAST(payload.data.coredata.accuracy.semiMinor AS FLOAT) AS coredataAccuracySemiMinor,
       payload.data.coredata.transmission AS coredataTransmission,
       CAST(payload.data.coredata.speed AS FLOAT) AS coredataSpeed,
       CAST(payload.data.coredata.heading AS FLOAT) AS coredataHeading,
       payload.data.coredata.brakes.wheelBrakes.leftFront AS coredataWheelBrakesLeftFront,
       payload.data.coredata.brakes.wheelBrakes.rightFront AS coredataWheelBrakesRightFront,
       payload.data.coredata.brakes.wheelBrakes.unavailable AS coredataWheelBrakesUnavailable,
       payload.data.coredata.brakes.wheelBrakes.leftRear AS coredataWheelBrakesLeftRear,
       payload.data.coredata.brakes.wheelBrakes.rightRear AS coredataWheelBrakesRightRear,
       payload.data.coredata.brakes.traction AS coredataBrakesTraction,
       payload.data.coredata.brakes.abs AS coredataBrakesAbs,
       payload.data.coredata.brakes.scs AS coredataBrakesScs,
       payload.data.coredata.brakes.brakeBoost AS coredataBrakesBrakeBoost,
       payload.data.coredata.brakes.auxBrakes AS coredataBrakesAuxBrakes,
       payload.data.coredata.size.length AS coredataSizeLength,
       payload.data.coredata.size.width AS coredataSizeWidth
FROM wydot_bsm_tmp;

-- explode properties

CREATE TABLE wydot_bsm_partii_tmp STORED
AS
ORC tblproperties ("orc.compress" = "Zlib")
AS
SELECT reflect("java.util.UUID","randomUUID") partiiid,
       bsmid,
       partii
FROM wydot_bsm_tmp LATERAL VIEW explode (payload.data.partii) partiiTable AS partii;

INSERT INTO TABLE wydot_bsm_partii
SELECT partiiid,
       bsmid,
       partii.id AS id,
       CAST(partii.value.pathPrediction.confidence AS FLOAT) AS pathPredictionConfidence,
       CAST(partii.value.pathPrediction.radiusOfCurve AS FLOAT) AS pathPredictionRadiusOfCurve,
       CAST(partii.value.vehicleData.height AS FLOAT) AS vehicleDataHeight,
       partii.value.classDetails.fuelType AS classDetailsFuelType,
       partii.value.classDetails.hpmsType AS classDetailsHpmsType,
       partii.value.classDetails.keyType AS classDetailsKeyType,
       partii.value.classDetails.role AS classDetailsRole

FROM wydot_bsm_partii_tmp;

INSERT INTO TABLE wydot_bsm_partii_crumbdata
SELECT reflect("java.util.UUID","randomUUID") partiiCrumbDataId,
       partiiid,
       bsmid,
       CAST(pathHistoryCrumbData.elevationOffset AS FLOAT) AS elevationOffset,
       CAST(pathHistoryCrumbData.latOffset AS FLOAT) AS latOffset,
       CAST(pathHistoryCrumbData.lonOffset AS FLOAT) AS lonOffset,
       CAST(pathHistoryCrumbData.timeOffset AS FLOAT) AS timeOffset
FROM wydot_bsm_partii_tmp LATERAL VIEW explode (partii.value.pathHistory.crumbData) crumbDataTable AS pathHistoryCrumbData;

DROP TABLE IF EXISTS wydot_bsm_tmp;
DROP TABLE IF EXISTS wydot_bsm_partii_tmp;