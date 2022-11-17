DROP TABLE IF EXISTS wydot_speed_sensors_index_staging;
CREATE EXTERNAL TABLE IF NOT EXISTS wydot_speed_sensors_index_staging (
	deviceid  int,
	lat_decimal  float,
	long_decimal  float,
	road_code  string,
	sitename  string,
	devicename  string,
	sensortype  string,
	public_route  string,
	gis_route  string,
	direction  string,
	milepost  float,
	sensor_loc  string,
	nearest_rwis  string,
	rwis  string,
	backup_rwis  string,
	2015_adt  int,
	vsl_id  string,
	eb_vsl  int,
	wb_vsl  int,
	horiz_d  int,
	horiz_i  int,
	vert_i  float,
	vert_d  float,
	notes  string
 )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Corridor/IndexTables/DevicesSpeedSensors'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
);

DROP TABLE IF EXISTS wydot_segments_index_staging;
CREATE EXTERNAL TABLE IF NOT EXISTS wydot_segments_index_staging (
	route  string,
	beg_mp  float,
	end_mp  float,
	dir  string,
	vsl_corr  string,
	corr_id  string
 )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Corridor/IndexTables/DevicesSegments'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
);

DROP TABLE IF EXISTS wydot_rwis_index_staging;
CREATE EXTERNAL TABLE IF NOT EXISTS wydot_rwis_index_staging (
	deviceid  string,
	lat_decimal  float,
	long_decimal  float,
	road_code  string,
	sitename  string,
	public_route  string,
	direction  string,
	gis_route  string,
	milepost  float,
	offset  float,
	wxde_id  int,
	wxde_desc  string,
	wxde_lat  float,
	wxde_long  float,
	mesowest  string,
	priority_rwis  boolean
 )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Corridor/IndexTables/DevicesRWIS'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
);

DROP TABLE IF EXISTS wydot_speed_signs_index_staging;
CREATE EXTERNAL TABLE IF NOT EXISTS wydot_speed_signs_index_staging (
	milepost  float,
	route   string,
	direction  string,
	name  string,
	corridor  string,
	maxspeed  int
 )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Corridor/IndexTables/DevicesSpeedSigns'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
);

DROP TABLE IF EXISTS wydot_vlogs_query_summary_staging;
CREATE EXTERNAL TABLE IF NOT EXISTS wydot_vlogs_query_summary_staging (
	sensor          int,
	avgofspeed      float,
	countofvlogs    int,
	minoflane       int,
	maxoflane       int,
	countofspeed    int,
	countnullspeeds int,
	perfnull        float,
	startdate       string,
	enddate         string
 )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/Corridor/IndexTables/VlogsQuerySummary'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
);
