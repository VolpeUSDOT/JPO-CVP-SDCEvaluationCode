--------------------------------------------------------------
-- Insert the NYC_EVENTSPDCOMP table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_eventspdcomp SELECT * FROM nyc_eventspdcomp_staging;
