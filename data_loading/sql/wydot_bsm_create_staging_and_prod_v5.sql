--STAGE PREDEDUP TABLE

drop table if exists wydot_bsm_prededup_staging;

drop table if exists wydot_bsm_prededup;
drop table if exists wydot_bsm_dedup;
drop table if exists wydot_bsm_staging_duplicates;
drop table if exists wydot_bsm_staging_v5;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_bsm_prededup_staging (
    metadata struct<
        bsmSource:string,
        logFileName:string,
        recordType:string,
        securityResultCode:string,
        receivedMessageDetails:struct<
            locationData:struct<
                latitude:string,
                longitude:string,
                elevation:string,
                speed:string,
                heading:string
            >,
            rxSource:string
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
        dataType:string,
        data:struct<
            coreData:struct<
                msgCnt:int,
                id:string,
                secMark:int,
                position:struct<
                    latitude:string,
                    longitude:string,
                    elevation:string
                >,
                accelSet:struct<
                    accelLat:string,
                    accelLong:string,
                    accelVert:string,
                    accelYaw:string
                >,
                accuracy:struct<
                    semiMajor:string,
                    semiMinor:string
                >,
                transmission:string,
                speed:string,
                heading:string,
                brakes:struct<
                    wheelBrakes:struct<
                        leftFront:boolean,
                        rightFront:boolean,
                        unavailable:boolean,
                        leftRear:boolean,
                        rightRear:boolean
                    >,
                    traction:string,
                    abs:string,
                    scs:string,
                    brakeBoost:string,
                    auxBrakes:string
                >,
                size:struct<
                    width:int,
                    length:int
                >
            >,
            partII:array<
                struct<
                    id:string,
                    value:struct<
                        pathHistory:struct<
                            crumbdata:array<
                                struct<
                                    elevationOffset:string,
                                    latOffset:string,
                                    lonOffset:string,
                                    timeOffset:string
                                >
                            >
                        >,
                        classDetails:struct<
                            fuelType:string,
                            hpmsType:string,
                            keyType:int,
                            role:string
                        >,
                        vehicleData:struct<
                            height:string
                        >,
                        pathPrediction:struct<
                            confidence:string,
                            radiusOfCurve:string
                        >
                    >
                >
            >
        >
    >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  "ignore.malformed.json" = "true"
)

LOCATION
--  's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/BSM/v5/';
  's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/BSM/';

-- create table if it doesnt exist already
create table if not exists wydot_bsm_v5 like wydot_bsm_prededup_staging 
ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS ORC 
tblproperties("orc.compress"="Zlib");


--CREATE PREDEDUP TABLE WITH ROW ID COLUMN

drop table if exists wydot_bsm_prededup;

CREATE table if not exists wydot_bsm_prededup 
ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS ORC 
tblproperties("orc.compress"="Zlib")
AS SELECT
*,
ROW_NUMBER() OVER() as dedupid
FROM wydot_bsm_prededup_staging as staging;

-- SEPARATE UNIQUE RECORDS ON RELEVANT COLUMNS USING IN and grouping

drop table if exists wydot_bsm_dedup;

CREATE TABLE wydot_bsm_dedup 
ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS ORC 
tblproperties("orc.compress"="Zlib")
AS
select
  prededup.metadata,
  prededup.payload
from wydot_bsm_prededup as prededup
where prededup.dedupid in
(
  select 
    MIN(dedupid) as insertid
  FROM wydot_bsm_prededup
  group by payload.data.coredata.msgCnt, payload.data.coredata.secMark, payload.data.coredata.position.latitude, payload.data.coredata.position.longitude, payload.data.coredata.position.elevation, metadata.bsmSource, metadata.recordgeneratedat, metadata.logfilename
);

-- SEPARATE DUPLICATE RECORDS ON RELEVANT COLUMNS USING not in AND MIN OF DEDUPID AND GROUPING 

drop table if exists wydot_bsm_staging_duplicates;

CREATE TABLE wydot_bsm_staging_duplicates
ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS ORC 
tblproperties("orc.compress"="Zlib")
AS
select
  prededup.metadata,
  prededup.payload
from wydot_bsm_prededup as prededup
where prededup.dedupid not in
(
  select 
    MIN(dedupid) as insertid
  FROM wydot_bsm_prededup
  group by payload.data.coredata.msgCnt, payload.data.coredata.secMark, payload.data.coredata.position.latitude, payload.data.coredata.position.longitude, payload.data.coredata.position.elevation, metadata.bsmSource, metadata.recordgeneratedat, metadata.logfilename
);

--Separate unique records by joining to full v5 table

drop table wydot_bsm_staging_v5;

CREATE TABLE wydot_bsm_staging_v5
ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS ORC 
tblproperties("orc.compress"="Zlib")
AS
select 
    t1.metadata,
    t1.payload
from 
  (
    select
      CONCAT(payload.data.coredata.msgCnt, payload.data.coredata.secMark, payload.data.coredata.position.latitude, payload.data.coredata.position.longitude, payload.data.coredata.position.elevation, metadata.bsmSource, metadata.recordgeneratedat, metadata.logfilename) as concatid,
      metadata,
      payload
    from wydot_bsm_dedup as t1
   ) as t1
where not exists
 (
    select t2.concatid from 
      (
        select
          CONCAT(payload.data.coredata.msgCnt, payload.data.coredata.secMark, payload.data.coredata.position.latitude, payload.data.coredata.position.longitude, payload.data.coredata.position.elevation, metadata.bsmSource, metadata.recordgeneratedat, metadata.logfilename) as concatid
        from wydot_bsm_v5
      ) as t2
    where t1.concatid = t2.concatid
 );

--INSERT HISTORICAL DUPLICATES INTO DUPLICATES TABLE

INSERT INTO  TABLE wydot_bsm_staging_duplicates
select 
    t1.metadata,
    t1.payload
from 
  (
    select
      CONCAT(payload.data.coredata.msgCnt, payload.data.coredata.secMark, payload.data.coredata.position.latitude, payload.data.coredata.position.longitude, payload.data.coredata.position.elevation, metadata.bsmSource, metadata.recordgeneratedat, metadata.logfilename) as concatid,
      metadata,
      payload
    from wydot_bsm_dedup as t1
   ) as t1
where exists
 (
    select t2.concatid from 
      (
        select
          CONCAT(payload.data.coredata.msgCnt, payload.data.coredata.secMark, payload.data.coredata.position.latitude, payload.data.coredata.position.longitude, payload.data.coredata.position.elevation, metadata.bsmSource, metadata.recordgeneratedat, metadata.logfilename) as concatid
        from wydot_bsm_v5
      ) as t2
    where t1.concatid = t2.concatid
 );

-- CREATE Removed Records Table in Metadata
CREATE TABLE if not exists metadata.wydot_bsm_duplicates
ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS ORC 
tblproperties("orc.compress"="Zlib")
AS
select
    from_unixtime(unix_timestamp()) as dateremoved,
    a.metadata,
    a.payload
from (select * from wydot_bsm_staging_duplicates limit 0) as a;

--Insert into duplicates table 

INSERT INTO TABLE metadata.wydot_bsm_duplicates
select 
    from_unixtime(unix_timestamp()) as dateremoved,
    metadata,
    payload
from wydot_bsm_staging_duplicates;

drop table if exists wydot_bsm_prededup_staging;
drop table if exists wydot_bsm_prededup;
drop table if exists wydot_bsm_dedup;
drop table if exists wydot_bsm_staging_duplicates;

--DROP TABLE IF EXISTS wydot_bsm_v5;

CREATE TABLE IF NOT EXISTS `wydot_bsm_v5`(
   `metadata` struct<
        bsmSource:string,
        logFileName:string,
        recordType:string,
        securityResultCode:string,
        receivedMessageDetails:struct<
            locationData:struct<
                latitude:string,
                longitude:string,
                elevation:string,
                speed:string,
                heading:string
            >,
            rxSource:string
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
        recordGeneratedBy:
        string,sanitized:boolean
    >,
   `payload` struct<
        dataType:string,
        data:struct<
            coreData:struct<
                msgCnt:int,
                id:string,
                secMark:int,
                position:struct<
                    latitude:string,
                    longitude:string,
                    elevation:string
                >,
                accelSet:struct<
                    accelLat:string,
                    accelLong:string,
                    accelVert:string,
                    accelYaw:string
                >,
                accuracy:struct<
                    semiMajor:string,
                    semiMinor:string
                >,
                transmission:string,
                speed:string,
                heading:string,
                brakes:struct<
                    wheelBrakes:struct<
                        leftFront:boolean,
                        rightFront:boolean,
                        unavailable:boolean,
                        leftRear:boolean,
                        rightRear:boolean
                    >,
                    traction:string,
                    abs:string,
                    scs:string,
                    brakeBoost:string,
                    auxBrakes:string
                >,
                size:struct<
                    width:int,
                    length:int
                >
            >,
            partII:array<
                    struct<
                    id:string,
                    value:struct<
                        pathHistory:struct<
                            crumbdata:array<
                                struct<
                                    elevationOffset:string,
                                    latOffset:string,
                                    lonOffset:string,
                                    timeOffset:string
                                >
                            >
                        >,
                        classDetails:struct<
                            fuelType:string,
                            hpmsType:string,
                            keyType:int,
                            role:string
                        >,
                        vehicleData:struct<
                            height:string
                        >,
                        pathPrediction:struct<
                            confidence:string,
                            radiusOfCurve:string
                        >
                    >
                >
            >
        >
    >)
 ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
 STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 LOCATION
   'hdfs://HADOOP-SERVER-DOMAIN-NAME:9000/user/hive/warehouse/wydot_bsm_v5'
 TBLPROPERTIES (
   'last_modified_by'='hduser',
   'last_modified_time'='1527797056',
   'orc.compress'='Zlib',
   'transient_lastDdlTime'='1529059196');
