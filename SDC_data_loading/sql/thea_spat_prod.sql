INSERT INTO TABLE thea_spat SELECT * FROM thea_spat_staging a WHERE a.metadata.dataType IS NOT NULL;


