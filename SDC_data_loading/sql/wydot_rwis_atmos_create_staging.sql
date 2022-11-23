DROP TABLE IF EXISTS wydot_rwis_atmos_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_rwis_atmos_staging(
        DEVICEID int,
        SITEID int,
        SENSORID int,
        UTC string,
        `LOCAL` string,
        AIRTEMP float,
        DEWTEMP float,
        RELATIVE_HUMIDITY float,
        WINDSPEED_AVG int,
        WINDSPEED_GUST int,
        WINDDIR_AVG int,
        WINDDIR string,
        PRESSURE int,
        PRECIP_INTENSITY string,
        PRECIP_TYPE string,
        PRECIP_RATE int,
        PRECIP_ACCUMULATION int,
        VISIBILITY float,
        VISIBILITYFT int)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 
      --'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/RWIS/ATMOS/'
      's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/RWIS/ATMOS/'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );
