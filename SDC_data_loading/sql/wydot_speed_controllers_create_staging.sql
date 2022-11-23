drop table if exists wydot_speed_controllers_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_speed_controllers_staging(
        controller int, 
        highway string, 
        direction string,
        milepost float,
        longitude float,
        latitude float)
    ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
    WITH SERDEPROPERTIES (
       "skip.header.line.count"="1",
       "separatorChar" = ",",
       "quoteChar"     = "'",
       "escapeChar"    = "\\"
    )
    STORED AS TEXTFILE
    location 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Speed/Controllers/';
    --location 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Speed/Controllers/';

