-- MERGER of BSM v4 and v5

-- LOAD BSM v4 data
DROP TABLE IF EXISTS wydot_bsm_tmp;
DROP TABLE IF EXISTS wydot_bsm_core;
DROP TABLE IF EXISTS wydot_bsm_partii;
DROP TABLE IF EXISTS wydot_bsm_partii_tmp;
DROP TABLE IF EXISTS wydot_bsm_partii_crumbdata;

CREATE TABLE wydot_bsm_tmp STORED
AS
ORC tblproperties ("orc.compress" = "Zlib")
AS
SELECT reflect("java.util.UUID","randomUUID") bsmid,
       *
FROM wydot_bsm_v4;

CREATE TABLE wydot_bsm_core STORED
AS
ORC tblproperties ("orc.compress" = "Zlib")
AS
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
       metadata.validSignature AS metadataValidSignature,
       metadata.securityResultCode AS metadataSecurityResultCode,
       CAST(NULL as float) AS metadataReceivedMessageDetailsLocationDataLatitude,
       CAST(NULL as float) AS metadataReceivedMessageDetailsLocationDataLongitude,
       CAST(NULL as float) AS metadataReceivedMessageDetailsLocationDataElevation,
       CAST(NULL as float) AS metadataReceivedMessageDetailsLocationDataSpeed,
       CAST(NULL as float) AS metadataReceivedMessageDetailsLocationDataHeading,
       CAST(NULL as string) AS metadataReceivedMessageDetailsRxSource,
       metadata.sanitized AS metadataSanitized,
       payload.data.coredata.msgCnt AS coredataMsgCnt,
       payload.data.coredata.id AS coredataId,
       payload.data.coredata.secMark AS coredatasecMark,
       payload.data.coredata.position.latitude AS coredataLatitude,
       payload.data.coredata.position.longitude AS coredataLongitude,
       payload.data.coredata.position.elevation AS coredataElevation,
       payload.data.coredata.accelset.accelYaw AS coredataAccelYaw,
       CAST(NULL as float) AS coredataAccelLat,
       CAST(NULL as float) AS coredataAccelLong,
       CAST(NULL as float) AS coredataAccelVert,
       payload.data.coredata.accuracy.semiMajor AS coredataAccuracySemiMajor,
       payload.data.coredata.accuracy.semiMinor AS coredataAccuracySemiMinor,
       CAST(NULL as string) AS coredataTransmission,
       payload.data.coredata.speed AS coredataSpeed,
       payload.data.coredata.heading AS coredataHeading,
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
       payload.data.coredata.size.sizeLength AS coredataSizeLength,
       payload.data.coredata.size.sizeWidth AS coredataSizeWidth
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

CREATE TABLE wydot_bsm_partii STORED
AS
ORC tblproperties ("orc.compress" = "Zlib")
AS
SELECT partiiid,
       bsmid,
       partii.id AS id,
       partii.value.pathPrediction.confidence AS pathPredictionConfidence,
       partii.value.pathPrediction.radiusOfCurve AS pathPredictionRadiusOfCurve,
       CAST(NULL as float) AS vehicleDataHeight,
       CAST(NULL as string) AS classDetailsFuelType,
       CAST(NULL as string) AS classDetailsHpmsType,
       CAST(NULL as int) AS classDetailsKeyType,
       CAST(NULL as string) AS classDetailsRole
FROM wydot_bsm_partii_tmp;

CREATE TABLE wydot_bsm_partii_crumbdata STORED
AS
ORC tblproperties ("orc.compress" = "Zlib")
AS
SELECT reflect("java.util.UUID","randomUUID") partiiCrumbDataId,
       partiiid,
       bsmid,
       pathHistoryCrumbData.elevationOffset AS elevationOffset,
       pathHistoryCrumbData.latOffset AS latOffset,
       pathHistoryCrumbData.lonOffset AS lonOffset,
       pathHistoryCrumbData.timeOffset AS timeOffset
FROM wydot_bsm_partii_tmp LATERAL VIEW explode (partii.value.pathHistory.crumbData) crumbDataTable AS pathHistoryCrumbData;

-- LOAD BSM v5 data into tmp and extend into core
DROP TABLE IF EXISTS wydot_bsm_tmp;

CREATE TABLE wydot_bsm_tmp STORED
AS
ORC tblproperties ("orc.compress" = "Zlib")
AS
SELECT reflect("java.util.UUID","randomUUID") bsmid,
       *
FROM wydot_bsm_v5;

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

DROP TABLE IF EXISTS wydot_bsm_partii_tmp;

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