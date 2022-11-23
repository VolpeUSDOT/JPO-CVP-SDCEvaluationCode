--------------------------------------------------------------
-- Insert the NYC_EVENTPEDINXWALK table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventpedinxwalk SELECT * FROM nyc_eventpedinxwalk_staging;
