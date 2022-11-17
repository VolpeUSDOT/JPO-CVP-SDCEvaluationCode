--------------------------------------------------------------
-- Insert the NYC_EVENTEEBL table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventeebl SELECT * FROM nyc_eventeebl_staging;
