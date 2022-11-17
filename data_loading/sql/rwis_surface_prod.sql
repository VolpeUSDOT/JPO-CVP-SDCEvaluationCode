CREATE TABLE IF NOT EXISTS `wydot_rwis_surface`(
  `deviceid` int,
  `siteid` int,
  `surface_sensor_id` int,
  `sensor_location` string,
  `utc` string,
  `local` string,
  `surface_status` string,
  `surface_temp` int,
  `frz_temp` int,
  `chem_factor` int,
  `chem_pct` int,
  `depth` int,
  `ice_pct` int,
  `subsf_temp` int,
  `water_level` int)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_rwis_surface';

INSERT INTO TABLE wydot_rwis_surface SELECT * FROM wydot_rwis_surface_staging s WHERE s.deviceid != 0;
