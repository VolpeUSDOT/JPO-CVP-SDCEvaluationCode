drop table if exists wydot_speed_processed_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_speed_processed_staging(
        Date_Time string, 
        Sensor int,
        Speed float,
        Length float,
        Class int, 
        Lane int,
        RWIS string,
        WB_VSL int,
        EB_VSL int,
        Sensor_Loc string,
        MILEPOST float,
        LaneDir int,
        StationID string,
        RoadCond int,
        Vis int,
        RH int,
        SurfTemp int,
        WndSpd int,
        StormNum int,
        PostedSpd int,
        PostedSpd_VSLTime string,
        SpeedCompliant5 int,
        SpeedBuffer10 int,
        DataQuality string,
        stormcat int)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    --location 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Speed/Speed_processed/';
    location 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/Speed/Speed_processed/';
