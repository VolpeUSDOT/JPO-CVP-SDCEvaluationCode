CREATE TABLE IF NOT EXISTS `wydot_vsl`(
  `deviceid` int, 
  `utc` string, 
  `local` string, 
  `blank` string, 
  `vsl_mph` int)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_vsl'
TBLPROPERTIES (
  'transient_lastDdlTime'='1530017745');
  
INSERT INTO wydot_vsl  SELECT * FROM wydot_vsl_input_staging s WHERE s.deviceid != 0;
