DROP TABLE IF EXISTS thea_spat_staging; 

CREATE EXTERNAL TABLE IF NOT EXISTS thea_spat_staging (
	metadata struct<
      	schemaVersion:int,
        recordGeneratedBy:string,
        recordGeneratedAt:string,
    	logFileName:string,
    	kind:string,
    	psid:string,
    	RSUID:string,
    	externalID:string,
    	dataType:string
  	>,
  	payload struct<
  		data: struct<
  			SPAT: struct<
  				time_stamp:string,
  				intersections: struct<
  					IntersectionState: struct<
  						id: struct<
  							id: string
  						>,
  						revision:string,
  						status:string,
  						time_stamp:string,
  						enabledLanes: struct<
  							LaneID: array<string>
  						>,
  						states: struct<
  							MovementState: array<
  								struct<
  									signalGroup:string,
  									state_time_speed: struct<
  										MovementEvent: struct<
  											eventState: struct<
  												stop_And_Remain:string,
  												protected_Movement_Allowed:string
  											>,
  											timing: struct<
  												minEndTime:string,
  												maxEndTime:string
  											>
  										>
  									>
  								>
  							>
  						>
  					>
  				>
  			>
  		>
  	>
)

ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  "ignore.malformed.json" = "true",
  "mapping.time_stamp"="timeStamp",
  "mapping.state_time_speed"="state-time-speed",
  "mapping.stop_And_Remain"="stop-And-Remain",
  "mapping.protected_Movement_Allowed"="protected-Movement-Allowed"
)

LOCATION
  --'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/archive/SPAT/';
  's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/SPAT/';

------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `thea_spat` (
	`metadata` struct<
      	schemaVersion:int,
        recordGeneratedBy:string,
        recordGeneratedAt:string,
    	logFileName:string,
    	kind:string,
    	psid:string,
    	RSUID:string,
    	externalID:string,
    	dataType:string
  	>,
  	`payload` struct<
  		data: struct<
  			SPAT: struct<
  				time_stamp:string,
  				intersections: struct<
  					IntersectionState: struct<
  						id: struct<
  							id:string
  						>,
  						revision:string,
  						status:string,
  						time_stamp:string,
  						enabledLanes: struct<
  							LaneID: array<string>
  						>,
  						states: struct<
  							MovementState: array<
  								struct<
  									signalGroup:string,
  									state_time_speed: struct<
  										MovementEvent: struct<
  											eventState: struct<
  												stop_And_Remain:string,
  												protected_Movement_Allowed:string
  											>,
  											timing: struct<
  												minEndTime:string,
  												maxEndTime:string
  											>
  										>
  									>
  								>
  							>
  						>
  					>
  				>
  			>
  		>
  	>
)

ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
LOCATION
   'hdfs://HADOOP-SERVER-DOMAIN-NAME:9000/user/hive/warehouse/thea_spat'
TBLPROPERTIES (
   'last_modified_by'='hduser',
   'last_modified_time'='1527797056',
   'orc.compress'='Zlib',
   'transient_lastDdlTime'='1529059196');
