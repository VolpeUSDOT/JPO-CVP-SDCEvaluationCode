CREATE TABLE IF NOT EXISTS wydot_pikalert_wti_comp_success (
	event_process_time_utc  string COMMENT 'The UTC date/time that the record was created in the success table. When the PikAlert data and the WTI data was compared. MDY with military time and time zone',
	event_process_time_local  string COMMENT 'The date/time that the record was created in the success table using local time zone. When the PikAlert data and the WTI data was compared. MDY with military time and time zone',
	success_count  int COMMENT 'The count of identical PikAlert/WTI report comparisons'  
	)
COMMENT 
  'This table stores the count of all PikAlert and WTI comparisons that are identical, so that an accurate number of successes can be reported.'
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_pikalert_wti_comp_success'
;
  
INSERT INTO wydot_pikalert_wti_comp_success SELECT * FROM wydot_pikalert_wti_comp_success_staging;
