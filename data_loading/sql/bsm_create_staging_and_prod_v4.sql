 --DROP TABLE IF EXISTS wydot_bsm_staging_v4;

-- schema v4
CREATE EXTERNAL TABLE IF NOT EXISTS wydot_bsm_staging_v4 (
  metadata struct<
    bsmsource:string,
    logfilename:string,
    recordtype:string,
    payloadtype:string,
    serialid:struct<
        streamid:string,
        bundlesize:int,
        bundleid:int,
        recordid:int,
        serialnumber:int
    >,
    odereceivedat:string,
    schemaversion:int,
    recordgeneratedat:string,
    recordgeneratedby:string,
    validsignature:boolean,
    securityresultcode:string,
    sanitized:boolean
  >,
  payload struct<
    datatype:string,
    data:struct<
        coredata:struct<
            msgcnt:int,
            id:string,
            secmark:int,
            position:struct<
                latitude:float,
                longitude:float,
                elevation:float
            >,
            accelset:struct<
                accelyaw:float
            >,
            accuracy:struct<
                semimajor:float,
                semiminor:float
            >,
            speed:float,
            heading:float,
            brakes:struct<
                wheelbrakes:struct<
                    leftfront:boolean,
                    rightfront:boolean,
                    unavailable:boolean,
                    leftrear:boolean,
                    rightrear:boolean
                >,
                traction:string,
                abs:string,
                scs:string,
                brakeboost:string,
                auxbrakes:string
            >,
            size:struct<
                sizelength:int,
                sizewidth:int
            >
        >,
        partii:array<
            struct<
                id:string,
                value:struct<
                    pathhistory:struct<
                        crumbdata:array<
                            struct<
                                elevationoffset:float,
                                latoffset:float,
                                lonoffset:float,
                                timeoffset:float
                            >
                        >
                    >,
                    pathprediction:struct<
                        confidence:float,
                        radiusofcurve:float
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
--  's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/BSM/v4/';
  's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/BSM/';

--DROP TABLE IF EXISTS wydot_bsm_v4;

CREATE TABLE IF NOT EXISTS `wydot_bsm_v4`(
   `metadata` struct<bsmsource:string,logfilename:string,recordtype:string,payloadtype:string,serialid:struct<streamid:string,bundlesize:int,bundleid:int,recordid:int,serialnumber:int>,odereceivedat:string,schemaversion:int,recordgeneratedat:string,recordgeneratedby:string,validsignature:boolean,securityresultcode:string,sanitized:boolean>,
   `payload` struct<datatype:string,data:struct<coredata:struct<msgcnt:int,id:string,secmark:int,position:struct<latitude:float,longitude:float,elevation:float>,accelset:struct<accelyaw:float>,accuracy:struct<semimajor:float,semiminor:float>,speed:float,heading:float,brakes:struct<wheelbrakes:struct<leftfront:boolean,rightfront:boolean,unavailable:boolean,leftrear:boolean,rightrear:boolean>,traction:string,abs:string,scs:string,brakeboost:string,auxbrakes:string>,size:struct<sizelength:int,sizewidth:int>>,partii:array<struct<id:string,value:struct<pathhistory:struct<crumbdata:array<struct<elevationoffset:float,latoffset:float,lonoffset:float,timeoffset:float>>>,pathprediction:struct<confidence:float,radiusofcurve:float>>>>>>)
 ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
 STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 LOCATION
   'hdfs://HADOOP-SERVER-DOMAIN-NAME:9000/user/hive/warehouse/wydot_bsm_v4'
 TBLPROPERTIES (
   'last_modified_by'='hduser',
   'last_modified_time'='1527797056',
   'orc.compress'='Zlib',
   'transient_lastDdlTime'='1527866024');
