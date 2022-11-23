--------------------------------------------------------------
-- Insert the NYC_EVENTOVCCLEARANCELIMIT table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventovcclearancelimit SELECT * FROM nyc_eventovcclearancelimit_staging;
