--------------------------------------------------------------
-- Insert the THEA_TRANSIT table 
--------------------------------------------------------------
INSERT INTO TABLE thea_transit SELECT * FROM thea_transit_staging;
