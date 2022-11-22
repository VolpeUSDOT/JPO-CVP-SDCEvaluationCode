DROP TABLE IF EXISTS thea_bsm_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_bsm_staging (
  metadata struct<
    schemaVersion:int,
    recordGeneratedBy:string,
    recordGeneratedAt:string,
    logFileName:string,
    kind:string,
    bsmSource:string,
    psid:int,
    RSUID:string,
    externalID:string,
    dataType:string
  >,
  payload struct<dataType:string,
                 data:struct<
                              coreData:struct<msgCnt:int,
                                                id:string,
                                                secMark:int,
                                                lat:int,
                                                long:int,
                                                elev:int,
                                                accuracy:struct<
                                                    semiMajor:int,
                                                    semiMinor:int,
                                                    orientation:int>,
                                                speed:int,
                                                heading:int,
                                                angle:int,
                                                accelset:struct<
                                                    long:int,
                                                    lat:int,
                                                    vert:int,
                                                    yaw:int>,
                                                brakes:struct<
                                                              wheelBrakes:int,
                                                              traction:struct<
                                                                 unavailable:boolean,
                                                                 off:boolean,
                                                                 tractionOn:boolean,
                                                                 engaged:boolean>,
                                                              abs:struct<
                                                                 unavailable:boolean,
                                                                 off:boolean,
                                                                 absOn:boolean,
                                                                 engaged:boolean>,
                                                              scs:struct<
                                                                 unavailable:boolean,
                                                                 off:boolean,
                                                                 scsOn:boolean,
                                                                 engaged:boolean>,
                                                              brakeBoost:struct<
                                                                 unavailable:boolean,
                                                                 off:boolean,
                                                                 brakeBoostOn:boolean>,
                                                              auxBrakes:struct<
                                                                 unavailable:boolean,
                                                                 off:boolean,
                                                                 auxBrakesOn:boolean,
                                                                 reserved:boolean>
                                                             >,
                                                 size:struct<length:int,
                                                             width:int>
                                               >,
                                partII:struct<
                                    SEQUENCE:struct<
                                           partIIid:string,
                                           partIIValue:struct<
                                             VehicleSafetyExtensions:struct<
                                                  pathHistory:struct<
                                                      crumbdata:struct<PathHistoryPoint:array<struct<
                                                                        latOffset:int,
                                                                        lonOffset:int,
                                                                        elevationOffset:int,
                                                                        timeOffset:int>>>>,
                                                  pathPrediction:struct<
                                                                  confidence:int,
                                                                  radiusOfCurve:int>>>>>                                                                  
                 >>
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  "mapping.tractionOn"="on",
  "mapping.absOn"="on",
  "mapping.scsOn"="on",
  "mapping.brakeBoostOn"="on",
  "mapping.partiiid"="partii-id",
  "mapping.partiivalue"="partii-value",
  "ignore.malformed.json" = "true"
)

LOCATION
  --'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/archive/BSM/';
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/BSM/';
select * from thea_bsm_staging limit 1;
select payload.data.partII.SEQUENCE from thea_bsm_staging limit 1;

-- ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'



