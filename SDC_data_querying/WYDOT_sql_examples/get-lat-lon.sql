-- WYDOT BSM: Getting Latitude and Longitude

select payload.data.coredata.position.latitude
, payload.data.coredata.position.longitude 
from wydot_bsm limit 1;

