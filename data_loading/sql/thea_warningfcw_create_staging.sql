--------------------------------------------------------------
-- Create the THEA_WARNINGFCW_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS thea_warningfcw_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_warningfcw_staging(
  metadata struct<
    loguploadedat:string,
    msgcnt:int,
    burstcnt:int,
    burstid:bigint,
    hostvehicleid:string,
    logpsid:string,
    rsulist:string,
    receivedrsutimestamps:bigint,
    datalogid:string,
    loggeneratedat:string,
    eventtype:string,
    hvbsm:struct<
                  id:string,
                  lat:int,
                  long:int,
                  datetime:string>,
    rvbsm:struct<
                  id:string,
                  lat:int,
                  long:int,
                  datetime:string>,
    driverwarn:boolean,
    iscontrol:boolean,
    isdisabled:boolean
  >,
  payload string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES("ignore.malformed.json" = "true")
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/warningFCW/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/warningFCW/';

CREATE TABLE IF NOT EXISTS thea_warningfcw(
  metadata struct<
    loguploadedat:string,
    msgcnt:int,
    burstcnt:int,
    burstid:bigint,
    hostvehicleid:string,
    logpsid:string,
    rsulist:string,
    receivedrsutimestamps:bigint,
    datalogid:string,
    loggeneratedat:string,
    eventtype:string,
    hvbsm:struct<
                  id:string,
                  lat:int,
                  long:int,
                  datetime:string>,
    rvbsm:struct<
                  id:string,
                  lat:int,
                  long:int,
                  datetime:string>,
    driverwarn:boolean,
    iscontrol:boolean,
    isdisabled:boolean
  >,
  payload string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 TBLPROPERTIES (
   'orc.compress'='Zlib');
