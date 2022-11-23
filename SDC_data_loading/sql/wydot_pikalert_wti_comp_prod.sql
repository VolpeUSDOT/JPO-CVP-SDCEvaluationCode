
CREATE TABLE IF NOT EXISTS wydot_pikalert_wti_comp (
	eventid  int COMMENT 'Primary key of the table that will trigger a TRAC task.',
	event_process_time_utc  string COMMENT 'The UTC date/time that the record was created in the trigger table. When the PikAlert data and the WTI data was compared. MDY with military time and time zone',
	event_process_time_local  string COMMENT 'The date/time that the record was created in the trigger table using the local time zone. When the PikAlert data and the WTI data was compared. MDY with military time and time zone',
	road_code  string COMMENT 'The WTI reporting section ID.',
	direction  string COMMENT 'The direction that is affected (i.e. westbound; eastbound; northbound; southbound)',
	rc_description  string COMMENT 'The landmark description of the WTI reporting section.',
	wti_rpt_time_utc  string COMMENT 'The UTC date/time that the WTI report was entered into the database. MDY with military time and time zone',
	wti_rpt_time_local  string COMMENT 'The date/time that the WTI report was entered into the database using the local time zone. MDY with military time and time zone',
	wti_report  string COMMENT 'A summary of the WTI reported conditions from the TMC as WYDOT codes.',
	wti_eight_codes  int COMMENT 'WTI reported surface conditions.',
	wti_nine_codes  int COMMENT 'WTI reported atmospheric conditions.',
	wti_ebor  boolean COMMENT 'Was extreme blow over risk reported in the WTI conditions?  1 = yes; 0 = no',
	wti_c2lhpv  boolean COMMENT 'Was closed to light trailers and high-profile vehicles reported in the WTI conditions? 1 = yes; 0 = no',
	pikalert_sections  string COMMENT 'List of all PikAlert sections (by ID) that comprise the WTI reporting section.',
	pikalert_rpt_time_utc  string COMMENT 'The UTC date/time of the PikAlert nowcast. MDY with military time and time zone',
	pikalert_rpt_time_local  string COMMENT 'The date/time of the PikAlert nowcast using local time zone. MDY with military time and time zone',
	pikalert_precip  string COMMENT 'PikAlert reported precipitation type. Worst case based on all PikAlert sections associated with the WTI reporting section.',
	pikalert_pavement  string COMMENT 'PikAlert reported pavement conditions. Worst case based on all PikAlert sections associated with the WTI reporting section.',
	pikalert_visibility  string COMMENT 'PikAlert reported visibility conditions. Worst case based on all PikAlert sections associated with the WTI reporting section.',
	pikalert_blowover  string COMMENT 'PikAlert reported blowover risk conditions. Worst case based on all PikAlert sections associated with the WTI reporting section.',
	pikalert_suggestion  string COMMENT 'Conversion of Pikalert nowcast to WTI equivalent as WYDOT codes.',
	pikalert_report  string COMMENT 'A summary of the Pikalert nowcast conditions. This is essentially a concatenated description of the report.',
	tracid  int COMMENT 'ID assigned to the task in the TRAC system.',
	trac_priority  string COMMENT 'Determine what color will be used in the TRAC system',
	tmc_action  string COMMENT 'What action has the TMC taken? Accept; Ignore; Suppress',
	tmc_reason  string COMMENT 'If the TMC ignores the discrepancy between PikAlert and WTI they must indicate a reason',
	tmc_action_time_utc  string COMMENT 'The UTC date/time that the TMC took action on the TRAC task. MDY with military time and time zone',
	tmc_action_time_local  string COMMENT 'The date/time that the TMC took action on the TRAC task using local time zone. MDY with military time and time zone',
	tmc_action_comment  string COMMENT 'A free text field for additional information regarding the task.',
	wti_updated  boolean COMMENT 'Was the WTI updated as a result of this event? 1 = yes; 0 = no',
	dms_updated  boolean COMMENT 'Were DMS messages updated? 1 = yes; 0 = no',
	vsl_updated  boolean COMMENT 'Were VSL messages updated? 1 = yes; 0 = no',
	tmc_operator_id  string COMMENT 'The username of the TMC Operator that completes the task.',
	suspend_end  string COMMENT 'When the messages suppression is ended using local time zone. MDY with military time and time zone',
	rc_mileposts  string COMMENT 'The beginning and ending mileposts of the WTI reporting section',
	route  string COMMENT 'The common route name for the WTI reporting section',
	from_landmark  string COMMENT 'The beginning landmark of the WTI reporting section.',
	to_landmark  string COMMENT 'The ending landmark of the WTI reporting section.',
	from_mp  float COMMENT 'The beginning milepost of the WTI reporting section.',
	to_mp  float COMMENT 'The ending milepost of the WTI reporting section.',
	pikalert_suggestion_text  string COMMENT 'Conversion of Pikalert nowcast to WTI equivalent as text description.',
	wti_report_text  string COMMENT 'A summary of the WTI reported conditions from the TMC as text description.',
	district  int COMMENT 'The ending milepost of the WTI reporting section.'
	)
COMMENT 
  'This table contains the discrepancy between the PikAlert nowcast and the Wyoming Traveler Information (WTI) reported road conditions; also contains relevant timestamps, location information, recommended actions, and actual actions taken by the TMC operator.'
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://hdfs-master:9000/user/hive/warehouse/wydot_pikalert_wti_comp'
;
  
INSERT INTO wydot_pikalert_wti_comp SELECT * FROM wydot_pikalert_wti_comp_staging;
