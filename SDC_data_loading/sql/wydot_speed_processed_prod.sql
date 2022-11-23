--DROP TABLE IF EXISTS wydot_speed_processed;

CREATE TABLE IF NOT EXISTS `wydot_speed_processed`(            
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
 ROW FORMAT SERDE                                   
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'      
 STORED AS INPUTFORMAT                              
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'  
 OUTPUTFORMAT                                       
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' 
 LOCATION                                           
   'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_speed_processed' 
 TBLPROPERTIES (                                    
   'orc.compress'='Zlib',                           
'transient_lastDdlTime'='1529072438');

INSERT INTO TABLE wydot_speed_processed 
SELECT * 
from wydot_speed_processed_staging
WHERE date_time != 'Date_Time';