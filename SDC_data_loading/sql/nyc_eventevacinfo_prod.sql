--------------------------------------------------------------
-- Insert the NYC_EVENTEVACINFO table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventevacinfo SELECT * FROM nyc_eventevacinfo_staging;
