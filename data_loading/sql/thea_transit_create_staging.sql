DROP TABLE IF EXISTS thea_transit_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_transit_staging(
        TRIP_ID string,
        VEHICLE_ID string,
        STOP_CODE string,
        STOP_NAME string,
        STOP_ID string,
        STOP_LAT double,
        STOP_LONG double,
        SCH_TIME bigint,
        NEAREST_STATION string,
        `TIMESTAMP` timestamp,
        NEAR_STOP_LONG double,
        NEAR_STOP_LAT double,
        NEAR_STOP_TIME bigint)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/Transit/'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );

CREATE TABLE IF NOT EXISTS thea_transit(
        TRIP_ID string,
        VEHICLE_ID string,
        STOP_CODE string,
        STOP_NAME string,
        STOP_ID string,
        STOP_LAT double,
        STOP_LONG double,
        SCH_TIME bigint,
        NEAREST_STATION string,
        `TIMESTAMP` timestamp,
        NEAR_STOP_LONG double,
        NEAR_STOP_LAT double,
        NEAR_STOP_TIME bigint)
    ROW FORMAT SERDE 
      'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
    STORED AS INPUTFORMAT 
      'org.apache.hadoop.mapred.TextInputFormat' 
    OUTPUTFORMAT 
      'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
    LOCATION
      'hdfs://HADOOP-SERVER-DOMAIN-NAME:9000/user/hive/warehouse/thea_transit'
    TBLPROPERTIES (
      'transient_lastDdlTime'='1530017745');
