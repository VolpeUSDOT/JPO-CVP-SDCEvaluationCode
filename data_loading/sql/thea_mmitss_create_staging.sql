DROP TABLE IF EXISTS thea_mmitss_staging;

CREATE EXTERNAL TABLE if not exists thea_mmitss_staging (
  metadata struct<
  	datatype:string, 
  	kind:string, 
  	logfilename:string, 
  	psid:string, 
  	recordgeneratedat:string, 
  	recordgeneratedby:string, 
  	rsuid:string, 
  	schemaversion:int
  >,
  payload struct<
  	queuelen:array<
  		struct<
  			approach:string, 
  			lane:string, 
  			queue_count:string, 
  			queue_len:string, 
  			vehicle_count:string
  		>
  	>,
  	trafPerf:array<
  		struct<
  			delay:string,
  			throughput:string,
  			num_stops:string,
  			movement:string,
  			travel_time:string
  		>
  	>
  >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'

WITH SERDEPROPERTIES (
  "ignore.malformed.json" = "true"
)

LOCATION
  --'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/archive/MMITSS/';
's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/MMITSS/';

------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS thea_mmitss (
  metadata struct<
  	datatype:string, 
  	kind:string, 
  	logfilename:string, 
  	psid:string, 
  	recordgeneratedat:string, 
  	recordgeneratedby:string, 
  	rsuid:string, 
  	schemaversion:int
  >,
  payload struct<
  	queuelen:array<
  		struct<
  			approach:string, 
  			lane:string, 
  			queue_count:string, 
  			queue_len:string, 
  			vehicle_count:string
  		>
  	>,
  	trafPerf:array<
  		struct<
  			delay:string,
  			throughput:string,
  			num_stops:string,
  			movement:string,
  			travel_time:string
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
   'hdfs://HADOOP-SERVER-DOMAIN-NAME:9000/user/hive/warehouse/thea_mmitss'
TBLPROPERTIES (
   'last_modified_by'='hduser',
   'last_modified_time'='1527797056',
   'orc.compress'='Zlib',
   'transient_lastDdlTime'='1529059196');
