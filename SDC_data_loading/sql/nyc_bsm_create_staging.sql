--------------------------------------------------------------
-- Create the NYC_BSM_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS nyc_bsm_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS nyc_bsm_staging(
    eventmsgseqnum int,
    bsmRecord struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        bsmmsg:struct<
            coredata:struct<
                msgcnt:int,
                id:string,
                accuracy:struct<
                    semimajor:int,
                    semiminor:int,
                    orientation:int
                >,
                transmission:string,
                angle:int,
                accelset:struct<
                    long_mpss:double,
                    lat_mpss:double,
                    vert_mpss:double,
                    yaw_dps:double
                >,
                brakes:struct<
                    wheelbrakes:string,
                    traction:string,
                    abs:string,
                    scs:string,
                    brakeboost:string,
                    auxbrakes:string
                >,
                size:struct<
                    width:string,
                    length:string
                >,
                x_m:double,
                y_m:double,
                z_m:double,
                t_s:double,
                speed_mps:double,
                heading_deg:double
            >,
            partii:array<
                struct<
                    partiiid:int,
                    partiivalue:struct<
                        pathhistory:struct<
                            crumbdata:array<
                                struct<
                                    xoffset_m:double,
                                    yoffset_m:double,
                                    zoffset_m:double,
                                    toffset_s:double
                                >
                            >
                        >,
                        pathprediction:struct<
                            radiusofcurve:bigint,
                            confidence:int
                        >,
                        classification:int,
                        vehicledata:struct<
                            height:int,
                            mass:int
                        >
                    >
                >
            >
        >
    >,
    vehiclerole string,
    eventid string,
    eventtype string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES(
 "ignore.malformed.json" = "true",
 "mapping.partiiid"="partii-id",
 "mapping.partiivalue"="partii-value"
)
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/BSM/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/BSM/';

CREATE TABLE IF NOT EXISTS nyc_bsm(
    eventmsgseqnum int,
    bsmRecord struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        bsmmsg:struct<
            coredata:struct<
                msgcnt:int,
                id:string,
                accuracy:struct<
                    semimajor:int,
                    semiminor:int,
                    orientation:int
                >,
                transmission:string,
                angle:int,
                accelset:struct<
                    long_mpss:double,
                    lat_mpss:double,
                    vert_mpss:double,
                    yaw_dps:double
                >,
                brakes:struct<
                    wheelbrakes:string,
                    traction:string,
                    abs:string,
                    scs:string,
                    brakeboost:string,
                    auxbrakes:string
                >,
                size:struct<
                    width:string,
                    length:string
                >,
                x_m:double,
                y_m:double,
                z_m:double,
                t_s:double,
                speed_mps:double,
                heading_deg:double
            >,
            partii:array<
                struct<
                    partiiid:int,
                    partiivalue:struct<
                        pathhistory:struct<
                            crumbdata:array<
                                struct<
                                    xoffset_m:double,
                                    yoffset_m:double,
                                    zoffset_m:double,
                                    toffset_s:double
                                >
                            >
                        >,
                        pathprediction:struct<
                            radiusofcurve:bigint,
                            confidence:int
                        >,
                        classification:int,
                        vehicledata:struct<
                            height:int,
                            mass:int
                        >
                    >
                >
            >
        >
    >,
    vehiclerole string,
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
