--------------------------------------------------------------
-- Create the NYC_MAP_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS nyc_map_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS nyc_map_staging(
    seqnum int,
    maprecact struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        mapmsg:struct<
            layertype:string,
            layerid:int,
            intersections:array<
                struct<
                    id:struct<
                        id:string
                    >,
                    refpoint:struct<
                        x_m:double,
                        y_m:double,
                        z_m:double
                    >,
                    lanewidth:int,
                    speedlimits:array<
                        struct<
                            type:string,
                            speed_mps:double
                        >
                    >,
                    laneset:array<
                        struct<
                            laneid:int,
                            ingressapproach:int,
                            laneattributes:struct<
                                directionaluse:string,
                                sharedwidth:string,
                                lanetype:struct<
                                    bikelane:string
                                >
                            >,
                            maneuvers:string,
                            nodelist:struct<
                                nodes:array<
                                    struct<
                                        delta:struct<
                                            nodexy1:struct<
                                                x:int,
                                                y:int>,
                                            nodexy2:struct<
                                                x:int,
                                                y:int>,
                                            nodexy3:struct<
                                                x:int,
                                                y:int>,
                                            nodexy4:struct<
                                                x:int,
                                                y:int>,
                                            nodexy5:struct<
                                                x:int,
                                                y:int>,
                                            nodexy6:struct<
                                                x:int,
                                                y:int>
                                        >,
                                        attributes:struct<
                                            dwidth:int,
                                            delevation:int
                                        >
                                    >
                                >
                            >,
                            connectsto:array<
                                struct<
                                    connectinglane:struct<
                                        lane:int,
                                        maneuver:string
                                    >,
                                    signalgroup:int,
                                    connectionid:int
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
WITH SERDEPROPERTIES(
 "ignore.malformed.json" = "true",
 "mapping.nodexy1"="node-xy1",
 "mapping.nodexy2"="node-xy2",
 "mapping.nodexy3"="node-xy3",
 "mapping.nodexy4"="node-xy4",
 "mapping.nodexy5"="node-xy5",
 "mapping.nodexy6"="node-xy6"
)
LOCATION 
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/MAP/';
--'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/nyc/MAP/';

CREATE TABLE IF NOT EXISTS nyc_map(
    seqnum int,
    maprecact struct<
        msgheader:struct<
            myrflevel:int,
            authenticated:boolean
        >,
        mapmsg:struct<
            layertype:string,
            layerid:int,
            intersections:array<
                struct<
                    id:struct<
                        id:string
                    >,
                    refpoint:struct<
                        x_m:double,
                        y_m:double,
                        z_m:double
                    >,
                    lanewidth:int,
                    speedlimits:array<
                        struct<
                            type:string,
                            speed_mps:double
                        >
                    >,
                    laneset:array<
                        struct<
                            laneid:int,
                            ingressapproach:int,
                            laneattributes:struct<
                                directionaluse:string,
                                sharedwidth:string,
                                lanetype:struct<
                                    bikelane:string
                                >
                            >,
                            maneuvers:string,
                            nodelist:struct<
                                nodes:array<
                                    struct<
                                        delta:struct<
                                            nodexy1:struct<
                                                x:int,
                                                y:int>,
                                            nodexy2:struct<
                                                x:int,
                                                y:int>,
                                            nodexy3:struct<
                                                x:int,
                                                y:int>,
                                            nodexy4:struct<
                                                x:int,
                                                y:int>,
                                            nodexy5:struct<
                                                x:int,
                                                y:int>,
                                            nodexy6:struct<
                                                x:int,
                                                y:int>
                                        >,
                                        attributes:struct<
                                            dwidth:int,
                                            delevation:int
                                        >
                                    >
                                >
                            >,
                            connectsto:array<
                                struct<
                                    connectinglane:struct<
                                        lane:int,
                                        maneuver:string
                                    >,
                                    signalgroup:int,
                                    connectionid:int
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
