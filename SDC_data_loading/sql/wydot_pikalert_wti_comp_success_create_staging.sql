DROP TABLE IF EXISTS wydot_pikalert_wti_comp_success_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_pikalert_wti_comp_success_staging(
	event_process_time_utc  string,
	event_process_time_local  string,
	success_count  int
	)
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    LINES TERMINATED by '\n'
    STORED AS TEXTFILE
    LOCATION 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/Pikalert/WTI_COMP_SUCCESS'
    TBLPROPERTIES (
        "skip.header.line.count" = "1"
    );
