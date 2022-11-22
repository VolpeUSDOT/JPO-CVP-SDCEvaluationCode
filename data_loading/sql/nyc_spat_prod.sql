--------------------------------------------------------------
-- Insert the NYC_SPAT table 
--------------------------------------------------------------
INSERT INTO TABLE nyc_spat SELECT * FROM nyc_spat_staging;
