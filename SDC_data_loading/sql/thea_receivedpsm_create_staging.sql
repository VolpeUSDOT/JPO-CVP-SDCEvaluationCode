--------------------------------------------------------------
-- Create the THEA_RECEIVEDPSM_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS thea_receivedpsm_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_receivedpsm_staging(
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
        dot3:struct<
            channel:int,
            psid:string,
            signal:struct<
                rxstrength:int>,
            datarate:int,
            timeslot:int>
    >,
    payload struct<
        messageframe:struct<
            messageid:int,
            value:struct<
                personalsafetymessage:struct<
                    basictype:string,
                    secmark:int,
                    msgcnt:int,
                    id:string,
                    position:struct<
                        lat:bigint,
                        long:bigint>,
                    accuracy:struct<
                        semimajor:int,
                        semiminor:int,
                        orientation:int>,
                    speed:int,
                    heading:int,
                    pathprediction:struct<
                        radiusofcurve:int,
                        confidence:int>
                >
            >
        >
    >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES(
 "ignore.malformed.json" = "true"
)
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/receivedPSM/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/receivedPSM/';

CREATE TABLE IF NOT EXISTS thea_receivedpsm(
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
        dot3:struct<
            channel:int,
            psid:string,
            signal:struct<
                rxstrength:int>,
            datarate:int,
            timeslot:int>
    >,
    payload struct<
        messageframe:struct<
            messageid:int,
            value:struct<
                personalsafetymessage:struct<
                    basictype:string,
                    secmark:int,
                    msgcnt:int,
                    id:string,
                    position:struct<
                        lat:bigint,
                        long:bigint>,
                    accuracy:struct<
                        semimajor:int,
                        semiminor:int,
                        orientation:int>,
                    speed:int,
                    heading:int,
                    pathprediction:struct<
                        radiusofcurve:int,
                        confidence:int>
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

