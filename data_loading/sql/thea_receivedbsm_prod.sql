--------------------------------------------------------------
-- Create the THEA_RECEIVEDBSM table 
--------------------------------------------------------------
INSERT INTO TABLE thea_receivedbsm SELECT * FROM thea_receivedbsm_staging;
