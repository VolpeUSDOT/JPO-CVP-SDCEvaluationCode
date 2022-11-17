--------------------------------------------------------------
-- Insert the THEA_BLUETOOTH_RAW table 
--------------------------------------------------------------
INSERT INTO TABLE thea_bluetooth_raw SELECT * FROM thea_bluetooth_raw_staging;
