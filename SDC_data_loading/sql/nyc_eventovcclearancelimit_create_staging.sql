--------------------------------------------------------------
-- Create the NYC_EVENTOVCCLEARANCELIMIT_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS nyc_eventovcclearancelimit_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS nyc_eventovcclearancelimit_staging(
  eventheader struct<
    locationsource:string,
    asdfirmwareversion:string,
    eventalertactive:boolean,
    eventalertsent:boolean,
    eventalertheard:boolean,
    hostvehid:string,
    targetvehid:string,
    triggerhvseqnum:int,
    triggertvseqnum:int,
    eventtype:string,
    parameters:struct<
                  recordingroi:string,
                  timerecordbefore:string,
                  timerecordfollow:string,
                  timerecordresolution:string,
                  minspdthreshold:string,
                  postedheightlimit:string,
                  postedsizelimit:string>,
    grpid:int,
    eventstatus:string,
    eventtimebin:string,
    eventlocationbin:string,
    weathercondition:string,
    airtempurature:int,
    precipitation1hr:string,
    windspeed:string
  >,
  eventid string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES("ignore.malformed.json" = "true")
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/eventOVCCLEARANCELIMIT/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/eventOVCCLEARANCELIMIT/';

CREATE TABLE IF NOT EXISTS nyc_eventovcclearancelimit(
  eventheader struct<
    locationsource:string,
    asdfirmwareversion:string,
    eventalertactive:boolean,
    eventalertsent:boolean,
    eventalertheard:boolean,
    hostvehid:string,
    targetvehid:string,
    triggerhvseqnum:int,
    triggertvseqnum:int,
    eventtype:string,
    parameters:struct<
                  recordingroi:string,
                  timerecordbefore:string,
                  timerecordfollow:string,
                  timerecordresolution:string,
                  minspdthreshold:string,
                  postedheightlimit:string,
                  postedsizelimit:string>,
    grpid:int,
    eventstatus:string,
    eventtimebin:string,
    eventlocationbin:string,
    weathercondition:string,
    airtempurature:int,
    precipitation1hr:string,
    windspeed:string
  >,
  eventid string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 TBLPROPERTIES (
   'orc.compress'='Zlib');
