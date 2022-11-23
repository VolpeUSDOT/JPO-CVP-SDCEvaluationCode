DROP TABLE IF EXISTS wydot_vsl_input_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_vsl_input_staging(
        DEVICEID int,
        UTC string,
        `LOCAL` string,
        BLANK string,
        VSL_MPH int)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    --LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/VSL/'
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/VSL/'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );
