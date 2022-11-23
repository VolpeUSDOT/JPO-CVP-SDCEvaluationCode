--------------------------------------------------------------
-- Create the NYC_TIM_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS nyc_tim_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS nyc_tim_staging(
    seqnum int,
    timrecord struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        timmsg:struct<
            msgcnt:int,
            packetid:string,
            dataframes:array<
                struct<
                    ssptimrights:int,
                    frametype:string,
                    msgid:struct<
                        roadsignid:struct<
                            viewangle:string,
                            mutcdcode:string
                        >
                    >,
                    priority:int,
                    ssplocationrights:int,
                    sspmsgrights1:int,
                    sspmsgrights2:int,
                    content:struct<
                        advisory:array<
                            struct<
                                item:struct<
                                    itis:int,
                                    text:string
                                >
                            >
                        >
                    >
                >
            >
        >
    >,
    eventid string,
    eventtype string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES("ignore.malformed.json" = "true")
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/TIM/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/TIM/';

CREATE TABLE IF NOT EXISTS nyc_tim(
    seqnum int,
    timrecord struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        timmsg:struct<
            msgcnt:int,
            packetid:string,
            dataframes:array<
                struct<
                    ssptimrights:int,
                    frametype:string,
                    msgid:struct<
                        roadsignid:struct<
                            viewangle:string,
                            mutcdcode:string
                        >
                    >,
                    priority:int,
                    ssplocationrights:int,
                    sspmsgrights1:int,
                    sspmsgrights2:int,
                    content:struct<
                        advisory:array<
                            struct<
                                item:struct<
                                    itis:int,
                                    text:string
                                >
                            >
                        >
                    >
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
