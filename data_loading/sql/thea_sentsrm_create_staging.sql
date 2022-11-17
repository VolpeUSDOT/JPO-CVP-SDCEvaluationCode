--------------------------------------------------------------
-- Create the THEA_SENTSRM_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS thea_sentsrm_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_sentsrm_staging(
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
                signalrequestmessage:struct<
                    timestampp:int,
                    second:int,
                    sequencenumber:int,
                    requests:struct<
                        signalrequestpackage:struct<
                            request:struct<
                                id:struct<
                                    id:int>,
                                requestid:int,
                                requesttype:string,
                                inboundlane:struct<    
                                    lane:int>,
                                outboundlane:struct<
                                    lane:int>
                            >,
                            minute:int,
                            second:int,
                            duration:int
                        >
                    >,
                    requestor:struct<
                        id:struct<
                            entityid:int>,
                        type:struct<
                            role:string,
                            request:string
                        >,
                        position:struct<
                            position:struct<
                                lat:bigint,
                                long:bigint,
                                elevation:int
                            >,
                            heading:int
                        >,
                        name:string
                    >
                >
            >
        >
    >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES(
 "ignore.malformed.json" = "true",
 "mapping.timestampp"="timestamp"
)
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/sentSRM/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/sentSRM/';

CREATE TABLE IF NOT EXISTS thea_sentsrm(
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
                signalrequestmessage:struct<
                    timestampp:int,
                    second:int,
                    sequencenumber:int,
                    requests:struct<
                        signalrequestpackage:struct<
                            request:struct<
                                id:struct<
                                    id:int>,
                                requestid:int,
                                requesttype:string,
                                inboundlane:struct<    
                                    lane:int>,
                                outboundlane:struct<
                                    lane:int>
                            >,
                            minute:int,
                            second:int,
                            duration:int
                        >
                    >,
                    requestor:struct<
                        id:struct<
                            entityid:int>,
                        type:struct<
                            role:string,
                            request:string
                        >,
                        position:struct<
                            position:struct<
                                lat:bigint,
                                long:bigint,
                                elevation:int
                            >,
                            heading:int
                        >,
                        name:string
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

