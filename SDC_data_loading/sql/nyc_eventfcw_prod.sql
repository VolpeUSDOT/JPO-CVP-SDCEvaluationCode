--------------------------------------------------------------
-- Insert the NYC_EVENTFCW table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventfcw SELECT * FROM nyc_eventfcw_staging;
