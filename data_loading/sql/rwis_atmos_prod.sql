CREATE TABLE IF NOT EXISTS `wydot_rwis_atmos`(
  `deviceid` int,
  `siteid` int,
  `sensorid` int,
  `utc` string,
  `local` string,
  `airtemp` float,
  `dewtemp` float,
  `relative_humidity` float,
  `windspeed_avg` int,
  `windspeed_gust` int,
  `winddir_avg` int,
  `winddir` string,
  `pressure` int,
  `precip_intensity` string,
  `precip_type` string,
  `precip_rate` int,
  `precip_accumulation` int,
  `visibility` float,
  `visibilityft` int)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_rwis_atmos';

INSERT INTO TABLE wydot_rwis_atmos SELECT * FROM wydot_rwis_atmos_staging s WHERE s.deviceid != 0;