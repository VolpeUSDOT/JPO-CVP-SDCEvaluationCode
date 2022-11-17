DROP TABLE IF EXISTS thea_bluetooth_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_bluetooth_staging(
        PAIR_ID string,
        DOW string,
        TIME_OF_DAY timestamp,
        SAMPLE_SIZE int,
        STANDARD_DEVIATION double,
        COEFFICIENT_OF_VARIATION double,
        MEAN double,
        95TH_PERCENTILE double,
        BUFFER_TIME_INDEX double,
        PLANNING_TIME_INDEX double)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/Bluetooth/'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );

CREATE TABLE IF NOT EXISTS thea_bluetooth(
        PAIR_ID string,
        DOW string,
        TIME_OF_DAY timestamp,
        SAMPLE_SIZE int,
        STANDARD_DEVIATION double,
        COEFFICIENT_OF_VARIATION double,
        MEAN double,
        95TH_PERCENTILE double,
        BUFFER_TIME_INDEX double,
        PLANNING_TIME_INDEX double)
    ROW FORMAT SERDE 
      'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
    STORED AS INPUTFORMAT 
      'org.apache.hadoop.mapred.TextInputFormat' 
    OUTPUTFORMAT 
      'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
    LOCATION
      'hdfs://HADOOP-SERVER-DOMAIN-NAME:9000/user/hive/warehouse/thea_bluetooth'
    TBLPROPERTIES (
      'transient_lastDdlTime'='1530017745');
