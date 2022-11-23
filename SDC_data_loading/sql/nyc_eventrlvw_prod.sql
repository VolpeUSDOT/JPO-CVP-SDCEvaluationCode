--------------------------------------------------------------
-- Insert the NYC_EVENTRLVW table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventrlvw SELECT * FROM nyc_eventrlvw_staging;
