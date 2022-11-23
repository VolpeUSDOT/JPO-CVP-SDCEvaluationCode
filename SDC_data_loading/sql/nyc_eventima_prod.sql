--------------------------------------------------------------
-- Insert the NYC_EVENTIMA table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventima SELECT * FROM nyc_eventima_staging;
