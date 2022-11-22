drop table if exists wydot_speed_unprocessed_staging;

CREATE EXTERNAL TABLE wydot_speed_unprocessed_staging(
        utc string,
        localTime string,
        controller int,
        lane int,
        dataSource int,
        durationMs int,
        speedMph float,
        lengthFt float,
        vehClass int)
   ROW FORMAT SERDE
       'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
   WITH SERDEPROPERTIES (
       "skip.header.line.count"="1",
       'field.delim'=',',
       'serialization.format'=',')
   STORED AS TEXTFILE
   LOCATION
       's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/Speed/UnprocessedSpeed';
       --'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/Speed/Speed_unprocessed';
