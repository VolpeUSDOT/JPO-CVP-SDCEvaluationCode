INSERT INTO TABLE wydot_alert_v5 SELECT * FROM wydot_alert_v5_staging a WHERE a.metadata.recordType IS NOT NULL;
