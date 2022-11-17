--
--  SDC CRB-118:  Due to Hive bug 15444 (https://issues.apache.org/jira/browse/HIVE-15444)
--                (tez.queue.name is invalid after tez job running on CLI), only the First
--                command is run with the tez.queue.name specified via the beeline command
--                line.  This is the reason we have set tez.queue.name=platform.ingest;
--                before each SQL statement.  This is unfortunate to have the queue name
--                hard coded into this file instead of being able to use the Hive URL
--                syntax of the beeline command line.
--
--                This is NOT required between the "show tables;" and the first select
--                command because show tables is handled by HiveServer2
--                cached database statistics.
--

show tables;
select count(*) as wydot_bsm_v4_count from wydot_bsm_v4 limit 1;
set tez.queue.name=platform.ingest;
select count(*) as wydot_bsm_v5_count from wydot_bsm_v5 limit 1;
set tez.queue.name=platform.ingest;
select count(*) as wydot_bsm_core_count from wydot_bsm_core limit 1;

select count(*) as wydot_tim_count from wydot_tim limit 1;
set tez.queue.name=platform.ingest;
select count(*) as wydot_tim_v6_count from wydot_tim_v6 limit 1;
set tez.queue.name=platform.ingest;
select count(*) as wydot_tim_core_count from wydot_tim_core limit 1;

set tez.queue.name=platform.ingest;
select count(*) as wydot_vsl_count from wydot_vsl limit 1;

set tez.queue.name=platform.ingest;
select count(*) as wydot_speed_unprocessed_count from wydot_speed_unprocessed limit 1;
set tez.queue.name=platform.ingest;
select count(*) as wydot_speed_processed_count from wydot_speed_processed limit 1;

set tez.queue.name=platform.ingest;
select count(*) as wydot_rwis_atmos_count from wydot_rwis_atmos limit 1;
set tez.queue.name=platform.ingest;
select count(*) as wydot_rwis_surface_count from wydot_rwis_surface limit 1;

set tez.queue.name=platform.ingest;
select count(*) as wydot_alert_v5_count from wydot_alert_v5 limit 1;
set tez.queue.name=platform.ingest;
select count(*) as wydot_alert_core_count from wydot_alert_core limit 1;

set tez.queue.name=platform.ingest;
select count(*) as thea_bsm_v5_count from thea_bsm_v5 limit 1;
