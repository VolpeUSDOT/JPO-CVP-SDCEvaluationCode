DROP TABLE IF EXISTS wydot_speed_controllers;

CREATE TABLE wydot_speed_controllers STORED AS ORC tblproperties("orc.compress"="Zlib") AS SELECT * FROM wydot_speed_controllers_staging;

