--------------------------------------------------------------
-- Insert the THEA_WEATHER table 
--------------------------------------------------------------
INSERT INTO TABLE thea_weather SELECT * FROM thea_weather_staging;
