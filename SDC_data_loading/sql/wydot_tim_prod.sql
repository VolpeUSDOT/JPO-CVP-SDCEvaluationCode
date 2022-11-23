DROP TABLE IF EXISTS wydot_tim_v6;

CREATE TABLE IF NOT EXISTS wydot_tim_v6 LIKE wydot_tim_staging_v6 STORED AS ORC tblproperties("orc.compress"="Zlib");

