INSERT INTO TABLE thea_bsm_v5 SELECT * FROM thea_bsm_staging_v5 a WHERE a.metadata.bsmsource IS NOT NULL;
