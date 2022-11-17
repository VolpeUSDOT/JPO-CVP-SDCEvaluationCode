DROP TABLE IF EXISTS thea_bsm;

CREATE TABLE thea_bsm STORED AS ORC tblproperties("orc.compress"="Zlib") AS SELECT * FROM thea_bsm_staging;

