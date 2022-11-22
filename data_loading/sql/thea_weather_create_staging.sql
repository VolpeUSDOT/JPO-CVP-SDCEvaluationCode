DROP TABLE IF EXISTS thea_weather_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_weather_staging(
        CITY string,
        STATE string,
        ZIP string,
        OBS_CITY string,
        OBS_STATE string,
        OBS_LONGITUDE double,
        OBS_LATITUDE double,
        OBS_ELEVATION double,
        NEAREST_STATION string,
        `TIMESTAMP` timestamp,
        TEMP_F string,
        HUMIDITY string,
        VISIBILITY string,
        CLOUD_COVER string,
        DEWPOINT_F string,
        PRECIP_INTENSITY string,
        WIND_BEARING string,
        WIND_GUST string,
        WIND_SPEED string,
        STORM_BEARING string,
        STORM_DISTANCE string,
        PRESSURE string,
        OZONE string,
        UV_INDEX string)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/Weather/'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );

CREATE TABLE IF NOT EXISTS thea_weather(
        CITY string,
        STATE string,
        ZIP string,
        OBS_CITY string,
        OBS_STATE string,
        OBS_LONGITUDE double,
        OBS_LATITUDE double,
        OBS_ELEVATION double,
        NEAREST_STATION string,
        `TIMESTAMP` timestamp,
        TEMP_F string,
        HUMIDITY string,
        VISIBILITY string,
        CLOUD_COVER string,
        DEWPOINT_F string,
        PRECIP_INTENSITY string,
        WIND_BEARING string,
        WIND_GUST string,
        WIND_SPEED string,
        STORM_BEARING string,
        STORM_DISTANCE string,
        PRESSURE string,
        OZONE string,
        UV_INDEX string)
    ROW FORMAT SERDE 
      'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
    STORED AS INPUTFORMAT 
      'org.apache.hadoop.mapred.TextInputFormat' 
    OUTPUTFORMAT 
      'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
    LOCATION
      'hdfs://HADOOP-SERVER-DOMAIN-NAME:9000/user/hive/warehouse/thea_weather'
    TBLPROPERTIES (
      'transient_lastDdlTime'='1530017745');
