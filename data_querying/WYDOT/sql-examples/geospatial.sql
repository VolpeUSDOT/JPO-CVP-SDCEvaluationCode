-- Geospatial Queries
-- The Data Warehouse has geospatial querying capabilities. Functions such as 
-- ST_Point, ST_Polygon, ST_Contains and others can be used in queries. 
-- For the full list of supported functions see: https://github.com/Esri/spatial-framework-for-hadoop/wiki/UDF-Documentation 
-- 
-- As an example, here is a sample query to retrieve a count of messages 
-- generated by vehicles between latitudes 40 and 41 and longitudes between -106 and -105.

select count(*) from wydot_bsm where 
ST_Contains(ST_Polygon(40, -105, 41, -105, 41, -106, 40, -106), 
            ST_Point(payload.data.coredata.position.latitude, payload.data.coredata.position.longitude));

