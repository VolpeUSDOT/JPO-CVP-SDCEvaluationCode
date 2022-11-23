 CREATE EXTERNAL TABLE `wydot_omitted_vehicles_staging`(             
   `temp_id` string,                                
   `encoded_id` string)                             
 ROW FORMAT SERDE                                   
   'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'  
 STORED AS INPUTFORMAT                              
   'org.apache.hadoop.mapred.TextInputFormat'       
 OUTPUTFORMAT                                       
   'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat' 
LOCATION 's3a://v-dev-cvp/leftovers/wydot_omitted_vehicles/'
 TBLPROPERTIES (                                    
   'last_modified_by'='hduser',                     
   'last_modified_time'='1528396820',               
   'transient_lastDdlTime'='1528396820');

            
DROP TABLE IF EXISTS wydot_omitted_vehicles;

CREATE TABLE wydot_omitted_vehicles AS SELECT * FROM wydot_omitted_vehicles_staging;
 
DROP TABLE IF EXISTS wydot_omitted_vehicles_staging;


-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

CREATE TABLE wydot_storm_categories_staging 
LOCATION '/tmp/leftovers/wydot_storm_categories/'
AS SELECT * FROM wydot_storm_categories;




 CREATE EXTERNAL TABLE `wydot_storm_categories_staging`(             
   `roadcond` int,                                  
   `visibility` int,                                
   `rh` int,                                        
   `windspeed` int,                                 
   `surftemp` int,                                  
   `stormnum` int,                                  
   `stormcat` int)                                  
 ROW FORMAT SERDE                                   
   'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'  
 STORED AS INPUTFORMAT                              
   'org.apache.hadoop.mapred.TextInputFormat'       
 OUTPUTFORMAT                                       
   'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat' 
LOCATION 's3a://v-dev-cvp/leftovers/wydot_storm_categories/'
 TBLPROPERTIES (                                    
   'transient_lastDdlTime'='1528405372');

INSERT INTO TABLE wydot_storm_categories_staging SELECT * FROM wydot_storm_categories;







