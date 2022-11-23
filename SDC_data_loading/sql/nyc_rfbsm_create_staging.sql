--------------------------------------------------------------
-- Create the NYC_RFBSM_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS nyc_rfbsm_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS nyc_rfbsm_staging(
    rfid string,
    role string,
    bsmtime struct<
        year:int,
        month:int,
        day:int,
        hour:int,
        minute:int,
        second:int
    >,
    bsm struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        bsmmsg:struct<
            coredata:struct<
                msgcnt:int,
                id:string,
                secmark:int,
                lat:bigint,
                long:bigint,
                elev:int,
                accuracy:struct<
                    semimajor:int,
                    semiminor:int,
                    orientation:int
                >,
                transmission:string,
                speed:int,
                heading:int,
                angle:int,
                accelset:struct<
                    long:int,
                    lat:int,
                    vert:int,
                    yaw:int
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
                >
            >,
            partii:array<
                struct<
                    partiiid:int,
                    partiivalue:struct<
                        pathhistory:struct<
                            crumbdata:array<
                                struct<
                                    latoffset:int,
                                    lonoffset:int,
                                    elevationoffset:int,
                                    timeoffset:int
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
    >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES(
 "ignore.malformed.json" = "true",
 "mapping.partiiid"="partii-id",
 "mapping.partiivalue"="partii-value"
)
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/RFBSM/';

CREATE TABLE IF NOT EXISTS nyc_rfbsm(
    rfid string,
    role string,
    bsmtime struct<
        year:int,
        month:int,
        day:int,
        hour:int,
        minute:int,
        second:int
    >,
    bsm struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        bsmmsg:struct<
            coredata:struct<
                msgcnt:int,
                id:string,
                secmark:int,
                lat:bigint,
                long:bigint,
                elev:int,
                accuracy:struct<
                    semimajor:int,
                    semiminor:int,
                    orientation:int
                >,
                transmission:string,
                speed:int,
                heading:int,
                angle:int,
                accelset:struct<
                    long:int,
                    lat:int,
                    vert:int,
                    yaw:int
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
                >
            >,
            partii:array<
                struct<
                    partiiid:int,
                    partiivalue:struct<
                        pathhistory:struct<
                            crumbdata:array<
                                struct<
                                    latoffset:int,
                                    lonoffset:int,
                                    elevationoffset:int,
                                    timeoffset:int
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
    >
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 TBLPROPERTIES (
   'orc.compress'='Zlib');
