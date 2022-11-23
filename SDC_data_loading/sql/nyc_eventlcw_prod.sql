--------------------------------------------------------------
-- Insert the NYC_EVENTLCW table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventlcw SELECT * FROM nyc_eventlcw_staging;
