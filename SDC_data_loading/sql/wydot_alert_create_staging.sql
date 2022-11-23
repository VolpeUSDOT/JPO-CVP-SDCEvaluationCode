--DROP TABLE IF EXISTS wydot_alert_v5_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_alert_v5_staging (
    metadata struct<
        logFileName:string,
        recordType:string,
        receivedMessageDetails:struct<
            locationData:struct<
                latitude:string,
                longitude:string,
                elevation:string,
                speed:string,
                heading:string
            >
        >,
        payloadType:string,
        serialId:struct<
            streamId:string,
            bundleSize:int,
            bundleId:int,
            recordId:int,
            serialNumber:int
        >,
        odeReceivedAt:string,
        schemaVersion:int,
        recordGeneratedAt:string,
        recordGeneratedBy:string,
        sanitized:boolean
    >,
    payload struct<
        alert:string
    >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  "ignore.malformed.json" = "true"
)

LOCATION
  --'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/alert/';
  's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/alert/';

--DROP TABLE IF EXISTS wydot_alert_v5;

CREATE TABLE IF NOT EXISTS `wydot_alert_v5`(
    `metadata` struct<
        logFileName:string,
        recordType:string,
        receivedMessageDetails:struct<
            locationData:struct<
                latitude:string,
                longitude:string,
                elevation:string,
                speed:string,
                heading:string
            >
        >,
        payloadType:string,
        serialId:struct<
            streamId:string,
            bundleSize:int,
            bundleId:int,
            recordId:int,
            serialNumber:int
        >,
        odeReceivedAt:string,
        schemaVersion:int,
        recordGeneratedAt:string,
        recordGeneratedBy:string,
        sanitized:boolean
    >,
    `payload` struct<
        alert:string
    >)
 ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
 STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 TBLPROPERTIES (
   'orc.compress'='Zlib');
