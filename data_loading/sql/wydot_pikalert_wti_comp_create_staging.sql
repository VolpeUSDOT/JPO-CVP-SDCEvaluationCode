DROP TABLE IF EXISTS wydot_pikalert_comp_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_pikalert_comp_staging(
	eventid  int,
	event_process_time_utc  string,
	event_process_time_local  string,
	road_code  string,
	direction  string,
	rc_description  string,
	wti_rpt_time_utc  string,
	wti_rpt_time_local  string,
	wti_report  string,
	wti_eight_codes  int,
	wti_nine_codes  int,
	wti_ebor  boolean,
	wti_c2lhpv  boolean,
	pikalert_sections  string,
	pikalert_rpt_time_utc  string,
	pikalert_rpt_time_local  string,
	pikalert_precip  string,
	pikalert_pavement  string,
	pikalert_visibility  string,
	pikalert_blowover  string,
	pikalert_suggestion  string,
	pikalert_report  string,
	tracid  int,
	trac_priority  string,
	tmc_action  string,
	tmc_reason  string,
	tmc_action_time_utc  string,
	tmc_action_time_local  string,
	tmc_action_comment  string,
	wti_updated  boolean,
	dms_updated  boolean,
	vsl_updated  boolean,
	tmc_operator_id  string,
	suspend_end  string,
	rc_mileposts  string,
	route  string,
	from_landmark  string,
	to_landmark  string,
	from_mp  float,
	to_mp  float,
	pikalert_suggestion_text  string,
	wti_report_text  string,
	district  int
	)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/Pikalert/WTI_COMP'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );
