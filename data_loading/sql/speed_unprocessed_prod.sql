DROP TABLE IF EXISTS wydot_speed_unprocessed_tmp;

CREATE TABLE wydot_speed_unprocessed_tmp STORED AS ORC tblproperties("orc.compress"="Zlib") AS SELECT * FROM wydot_speed_unprocessed_staging;

CREATE TABLE IF NOT EXISTS `wydot_speed_unprocessed`(            
   `utc` timestamp,                                 
   `mountain` timestamp,                            
   `controller` int,                                
   `lane` int,                                      
   `datasource` int,                                
   `durationms` int,                                
   `speedmph` float,                                
   `lengthft` float,                                
   `vehclass` int)                                  
 ROW FORMAT SERDE                                   
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'      
 STORED AS INPUTFORMAT                              
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'  
 OUTPUTFORMAT                                       
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' 
 LOCATION                                           
   'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_speed_unprocessed' 
 TBLPROPERTIES (                                    
   'orc.compress'='Zlib',                           
'transient_lastDdlTime'='1529072438');

INSERT INTO TABLE wydot_speed_unprocessed 
SELECT  
        cast(concat(concat(substr(utc, 1,10), ' '), substr(utc, 12,8)) as timestamp) as utc,
        cast(concat(concat(substr(localTime, 1,10), ' '), substr(localTime, 12,8)) as timestamp) as mountain,
        controller,
        lane,
        dataSource,
        durationMs,
        speedMph,
        lengthFt,
        vehClass
FROM wydot_speed_unprocessed_tmp;

DROP TABLE IF EXISTS wydot_speed_unprocessed_tmp;

