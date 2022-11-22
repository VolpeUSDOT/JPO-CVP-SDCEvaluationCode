CREATE TABLE IF NOT EXISTS wydot_speed_sensors_index (
	deviceid     int    COMMENT 'Speed sensor device ID',
	lat_decimal  float  COMMENT 'Latitude in Decimal Degrees',
	long_decimal float  COMMENT 'Longitude in Decimal Degrees',
	road_code    string,
	sitename     string,
	devicename   string,
	sensortype   string,
	public_route string,
	gis_route    string COMMENT 'route ID needed to plot data in GIS',
	direction    string COMMENT 'B = both directions, I = increasing MP or Eastbound direction, D = decreasing MP or Westbound direction',
	milepost     float  COMMENT 'Milepost of speed sensor',
	sensor_loc   string COMMENT 'Location of speed sensor relative to closest lane (EB or WB)',
	nearest_rwis string COMMENT 'Closest Road Weather Information System',
	rwis         string COMMENT 'MesoWest Station ID',
	backup_rwis  string COMMENT 'Secondary RWIS station if data not available for primary RWIS',
	2015_adt     int    COMMENT '2015 Average Daily Traffic for both directions of travel',
	vsl_id       string COMMENT 'VSL sign ID',
	eb_vsl       int    COMMENT 'Sign ID for closest upstream speed sign for Eastbound observations. VSL sign IDs of 1 are static 75 mph. Signs and IDs of 2 are static 80 mph signs',
	wb_vsl       int    COMMENT 'Sign ID for closest upstream speed sign for Westbound observations. VSL sign IDs of 1 are static 75 mph. Signs and IDs of 2 are static 80 mph signs',
	horiz_d      int    COMMENT 'Horizontal curve category for Westbound direction. Categories 0 (tangent) and 1 (Radius > 5000) and 2 (R>2500) desirable',
	horiz_i      int    COMMENT 'Horizontal curve category for Eastbound direction. Categories 0 (tangent) and 1 (Radius > 5000) and 2 (R>2500) desirable',
	vert_i       float  COMMENT 'Road grade (%) in Eastbound direction',
	vert_d       float  COMMENT 'Road grade (%) in Westbound direction',
	notes        string
 )
	COMMENT 'Data from Corridor_Devices.xlsx'
	ROW FORMAT SERDE 
	  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
	STORED AS INPUTFORMAT 
	  'org.apache.hadoop.mapred.TextInputFormat' 
	OUTPUTFORMAT 
	  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
	LOCATION
	  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_speed_sensors_index';
INSERT INTO wydot_speed_sensors_index SELECT * FROM wydot_speed_sensors_index_staging;


CREATE TABLE IF NOT EXISTS wydot_segments_index (
	route    string COMMENT 'GIS Route name',
	beg_mp   float  COMMENT 'Begin milepost',
	end_mp   float  COMMENT 'End milepost',
	dir      string COMMENT 'I = increasing MP or Eastbound direction; D = decreasing MP or Westbound direction; Without Direction',
	vsl_corr string COMMENT 'VSL corridor name',
	corr_id  string COMMENT 'Corridor ID'
 )
	COMMENT 'Data from Corridor_Devices.xlsx'
	ROW FORMAT SERDE 
	  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
	STORED AS INPUTFORMAT 
	  'org.apache.hadoop.mapred.TextInputFormat' 
	OUTPUTFORMAT 
	  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
	LOCATION
	  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_segments_index';
INSERT INTO wydot_segments_index SELECT * FROM wydot_segments_index_staging;


CREATE TABLE IF NOT EXISTS wydot_rwis_index (
	deviceid      string  COMMENT 'RWIS ID',
	lat_decimal   float   COMMENT 'Latitude in Decimal Degrees',
	long_decimal  float   COMMENT 'Longitude in Decimal Degrees',
	road_code     string,
	sitename      string,
	public_route  string,
	direction     string  COMMENT 'I = increasing MP or Eastbound direction; D = decreasing MP or Westbound direction',
	gis_route     string  COMMENT 'GIS Route name',
	milepost      float,
	offset        float,
	wxde_id       int,
	wxde_desc     string,
	wxde_lat      float,
	wxde_long     float,
	mesowest      string  COMMENT 'MesoWest Station ID',
	priority_rwis boolean COMMENT 'True for a priority RWIS station; false otherwise.'
 )
	COMMENT 'Data from Corridor_Devices.xlsx'
	ROW FORMAT SERDE 
	  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
	STORED AS INPUTFORMAT 
	  'org.apache.hadoop.mapred.TextInputFormat' 
	OUTPUTFORMAT 
	  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
	LOCATION
	  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_rwis_index';
INSERT INTO wydot_rwis_index SELECT * FROM wydot_rwis_index_staging;


CREATE TABLE IF NOT EXISTS wydot_speed_signs_index (
	milepost   float  COMMENT 'Milepost',
	route      string COMMENT 'GIS Route name',
	direction  string COMMENT 'I = increasing MP or Eastbound direction; D = decreasing MP or Westbound direction',
	name       string COMMENT 'Sitename',
	corridor   string COMMENT 'Corridor name',
	maxspeed   int    COMMENT 'Max speed in mph'
 )
	COMMENT 'Data from Corridor_Devices.xlsx'
	ROW FORMAT SERDE 
	  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
	STORED AS INPUTFORMAT 
	  'org.apache.hadoop.mapred.TextInputFormat' 
	OUTPUTFORMAT 
	  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
	LOCATION
	  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_speed_signs_index';
INSERT INTO wydot_speed_signs_index SELECT * FROM wydot_speed_signs_index_staging;

CREATE TABLE IF NOT EXISTS wydot_vlogs_query_summary (
	sensor          int    COMMENT 'Speed sensor device ID',
	avgofspeed      float  COMMENT 'Average speed in mph',
	countofvlogs    int    COMMENT '[Count of Vlogs] = [Count of Speed] + [Count of Null Speeds]',
	minoflane       int,
	maxoflane       int,
	countofspeed    int    COMMENT 'Count of valid speed values',
	countnullspeeds int    COMMENT 'Count of null speed values',
	perfnull        float  COMMENT 'Percentage of null speeds, calculated by dividing [Count of Null Speeds] by [Count of Vlogs]',
	startdate       string COMMENT 'Local time',
	enddate         string COMMENT 'Local time'
)
	COMMENT 'Data from Vlogs_Query_Summary.xlsx'
	ROW FORMAT SERDE 
	  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
	STORED AS INPUTFORMAT 
	  'org.apache.hadoop.mapred.TextInputFormat' 
	OUTPUTFORMAT 
	  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
	LOCATION
	  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_vlogs_query_summary';
INSERT INTO wydot_vlogs_query_summary SELECT * FROM wydot_vlogs_query_summary_staging;


--DROP TABLE IF EXISTS wydot_vlogs_query_summary;
--CREATE TABLE wydot_vlogs_query_summary 
--	STORED AS ORC tblproperties("orc.compress"="Zlib") 
--	AS SELECT * FROM wydot_vlogs_query_summary_staging;

