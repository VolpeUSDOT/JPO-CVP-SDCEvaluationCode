INSERT INTO TABLE thea_tim SELECT * FROM thea_tim_staging a WHERE a.metadata.dataType IS NOT NULL;