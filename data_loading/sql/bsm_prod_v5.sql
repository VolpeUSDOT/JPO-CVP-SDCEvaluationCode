INSERT INTO TABLE wydot_bsm_v5 SELECT * FROM wydot_bsm_staging_v5 a WHERE a.metadata.recordgeneratedby IS NOT NULL;
