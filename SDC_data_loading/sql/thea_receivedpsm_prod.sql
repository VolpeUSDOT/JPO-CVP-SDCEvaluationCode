--------------------------------------------------------------
-- Insert the THEA_RECEIVEDPSM table 
--------------------------------------------------------------
INSERT INTO TABLE thea_receivedpsm SELECT * FROM thea_receivedpsm_staging;
