DROP TABLE IF EXISTS wydot_rwis_surface_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_rwis_surface_staging(
        DEVICEID int,
        SITEID int,
        SURFACE_SENSOR_ID int,
        SENSOR_LOCATION string,
        UTC string,
        `LOCAL` string,
        SURFACE_STATUS string,
        SURFACE_TEMP int,
        FRZ_TEMP int,
        CHEM_FACTOR int,
        CHEM_PCT int,
        DEPTH int,
        ICE_PCT int,
        SUBSF_TEMP int,
        WATER_LEVEL int)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/RWIS/SURFACE/'
    --LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/RWIS/SURFACE/'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );
