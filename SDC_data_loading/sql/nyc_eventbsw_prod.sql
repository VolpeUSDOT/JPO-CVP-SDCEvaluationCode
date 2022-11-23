--------------------------------------------------------------
-- Insert the NYC_EVENTBSW table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventbsw SELECT * FROM nyc_eventbsw_staging;
