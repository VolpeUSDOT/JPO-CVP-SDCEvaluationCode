--------------------------------------------------------------
-- Create the NYC_SPAT_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS nyc_spat_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS nyc_spat_staging(
    seqnum int,
    spatrecord struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        spatmsg:struct<
            intersections:array<
                struct<
                    id:struct<
                        id:string
                    >,
                    revision:int,
                    status:string,
                    states:array<
                        struct<
                            signalgroup:int,
                            statetimespeed:array<
                                struct<
                                    eventstate:string,
                                    timing:struct<
                                        confidence:int,
                                        maxendtime_s:double,
                                        minendtime_s:double,
                                        likelytime_s:double,
                                        nexttime_s:double
                                    >
                                >
                            >,
                            maneuverAssistList:array<
                                struct<
                                    connectionid:int,
                                    queuelength:int,
                                    availablestoragelength:int,
                                    waitonstop:boolean,
                                    pedbicycledetect:boolean
                                >
                            >
                        >
                    >,
                    time_sec:double
                >
            >
        >
    >,
    eventid string,
    eventtype string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES(
 "ignore.malformed.json" = "true",
 "mapping.statetimespeed"="state-time-speed"
)
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/SPAT/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/SPAT/';

CREATE TABLE IF NOT EXISTS nyc_spat(
    seqnum int,
    spatrecord struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        spatmsg:struct<
            intersections:array<
                struct<
                    id:struct<
                        id:string
                    >,
                    revision:int,
                    status:string,
                    states:array<
                        struct<
                            signalgroup:int,
                            statetimespeed:array<
                                struct<
                                    eventstate:string,
                                    timing:struct<
                                        confidence:int,
                                        maxendtime_s:double,
                                        minendtime_s:double,
                                        likelytime_s:double,
                                        nexttime_s:double
                                    >
                                >
                            >,
                            maneuverAssistList:array<
                                struct<
                                    connectionid:int,
                                    queuelength:int,
                                    availablestoragelength:int,
                                    waitonstop:boolean,
                                    pedbicycledetect:boolean
                                >
                            >
                        >
                    >,
                    time_sec:double
                >
            >
        >
    >,
    eventid string,
    eventtype string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 TBLPROPERTIES (
   'orc.compress'='Zlib');
