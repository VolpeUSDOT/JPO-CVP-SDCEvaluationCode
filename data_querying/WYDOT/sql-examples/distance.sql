----------------------------
-- Cars within 100 m from a given car
-- at the same minute
select 
-- first.bsmid, 
sub1.bsmid, 

first.metadatarecordgeneratedat f,
sub1.metadatarecordgeneratedat s,

-- ST_DISTANCE(ST_POINT(first.coredatalatitude, first.coredatalongitude), ST_POINT(sub1.coredatalatitude, sub1.coredatalongitude)) as distance,
ST_GeodesicLengthWGS84(ST_SetSRID(ST_LineString(first.coredatalatitude, first.coredatalongitude, sub1.coredatalatitude, sub1.coredatalongitude), 4326)) as geodistance

FROM
wydot_bsm_core sub1, wydot_bsm_core first

where 
first.bsmid = '2e631f81-06dc-460b-8db3-88cdc4ac4a5a'
AND first.bsmid <> sub1.bsmid
AND substr(first.metadatarecordgeneratedat, 0, 16) = substr(sub1.metadatarecordgeneratedat, 0, 16)
AND ST_GeodesicLengthWGS84(ST_SetSRID(ST_LineString(first.coredatalatitude, first.coredatalongitude, sub1.coredatalatitude, sub1.coredatalongitude), 4326)) < 100

limit 200;



----------------------------
-- Cars within 10 m from each other
-- at the same minute
select 
first.bsmid, 
sub1.bsmid, 
substr(first.metadatarecordgeneratedat, 0, 16),
first.metadatarecordgeneratedat f,
sub1.metadatarecordgeneratedat s,

ST_GeodesicLengthWGS84(ST_SetSRID(ST_LineString(first.coredatalatitude, first.coredatalongitude, sub1.coredatalatitude, sub1.coredatalongitude), 4326)) as geo

FROM
wydot_bsm_core sub1, wydot_bsm_core first

where 

substr(first.metadatarecordgeneratedat, 0, 13) = '2018-11-05T20'
AND substr(first.metadatarecordgeneratedat, 0, 16) = substr(sub1.metadatarecordgeneratedat, 0, 16)
AND first.bsmid <> sub1.bsmid
AND ST_GeodesicLengthWGS84(ST_SetSRID(ST_LineString(first.coredatalatitude, first.coredatalongitude, sub1.coredatalatitude, sub1.coredatalongitude), 4326)) < 10

limit 200;

-- find minutes
select distinct substr(first.metadatarecordgeneratedat, 0, 16) from wydot_bsm_core first
where substr(first.metadatarecordgeneratedat, 0, 13) = '2018-11-01T20' limit 100;


------------------------------
-------------------------------
----------------------------
-- Cars within 10 m from each other
-- wirhin 1 second
-- with speed greater than 10 (km/h? m/s?)
-- within 10 meters from each other
select
first.bsmid,
second.bsmid,
first.metadatarecordgeneratedat f,
second.metadatarecordgeneratedat s,
first.coredataspeed,
second.coredataspeed,

round(ST_GeodesicLengthWGS84(ST_SetSRID(ST_LineString(first.coredatalatitude, first.coredatalongitude, second.coredatalatitude, second.coredatalongitude), 4326)), 2) as geo

FROM
wydot_bsm_core first, wydot_bsm_core second

where

substr(first.metadatarecordgeneratedat, 0, 13) = '2018-11-05T20'
AND substr(first.metadatarecordgeneratedat, 0, 16) = substr(second.metadatarecordgeneratedat, 0, 16)
AND first.bsmid <> second.bsmid
AND first.coredataspeed > 10
AND ST_GeodesicLengthWGS84(ST_SetSRID(ST_LineString(first.coredatalatitude, first.coredatalongitude, second.coredatalatitude, second.coredatalongitude), 4326)) < 10
AND ABS(
unix_timestamp(regexp_replace(first.metadatarecordgeneratedat, 'T',' ')) -
unix_timestamp(regexp_replace(second.metadatarecordgeneratedat, 'T',' '))) <= 1

limit 200;


-- find minutes
select distinct substr(first.metadatarecordgeneratedat, 0, 16) from wydot_bsm_core first
where substr(first.metadatarecordgeneratedat, 0, 13) = '2018-11-01T20' limit 100;


