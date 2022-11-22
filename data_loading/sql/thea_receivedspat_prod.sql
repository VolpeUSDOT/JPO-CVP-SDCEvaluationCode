--------------------------------------------------------------
-- Insert the THEA_RECEIVEDSPAT table 
--------------------------------------------------------------
INSERT INTO TABLE thea_receivedspat SELECT * FROM thea_receivedspat_staging;
