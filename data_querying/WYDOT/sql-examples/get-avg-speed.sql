-- WYDOT Speed Data
-- There are 2 WYDOT speed data in the CV PEP Data Warehouse: 
-- wydot_speed_unprocessed2 and wydot_speed_processed. The following 
-- sample query displays average vehicle speed distribution 
-- by lane and it will work against either of the tables:

select lane, avg(speedmph) as speed_average 
from wydot_speed_unprocessed2 
group by lane
order by lane;

