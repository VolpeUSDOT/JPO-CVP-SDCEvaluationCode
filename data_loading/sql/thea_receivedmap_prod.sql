--------------------------------------------------------------
-- Insert the THEA_RECEIVEDMAP table 
--------------------------------------------------------------
INSERT INTO TABLE thea_receivedmap SELECT * FROM thea_receivedmap_staging;
