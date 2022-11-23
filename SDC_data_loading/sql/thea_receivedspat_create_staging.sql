--------------------------------------------------------------
-- Create the THEA_RECEIVEDSPAT_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS thea_receivedspat_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_receivedspat_staging(
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
                SPAT: struct<
                    time_stamp:string,
                    intersections: struct<
                        IntersectionState: struct<
                            id: struct<
                                id: string
                            >,
                            revision:string,
                            status:string,
                            time_stamp:string,
                            enabledLanes:struct<
                                LaneID:array<string>
                            >,
                            states:struct<
                                MovementState: array<
                                    struct<
                                        signalGroup:string,
                                        state_time_speed:struct<
                                            MovementEvent:struct<
                                                eventState:string,
                                                timing:struct<
                                                    minEndTime:string,
                                                    maxEndTime:string
                                                >
                                            >
                                        >
                                    >
                                >
                            >
                        >
                    >
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
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/receivedSPAT/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/OBU/receivedSPAT/';

CREATE TABLE IF NOT EXISTS thea_receivedspat(
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
                SPAT: struct<
                    time_stamp:string,
                    intersections: struct<
                        IntersectionState: struct<
                            id: struct<
                                id: string
                            >,
                            revision:string,
                            status:string,
                            time_stamp:string,
                            enabledLanes:struct<
                                LaneID:array<string>
                            >,
                            states:struct<
                                MovementState: array<
                                    struct<
                                        signalGroup:string,
                                        state_time_speed:struct<
                                            MovementEvent:struct<
                                                eventState:string,
                                                timing:struct<
                                                    minEndTime:string,
                                                    maxEndTime:string
                                                >
                                            >
                                        >
                                    >
                                >
                            >
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

