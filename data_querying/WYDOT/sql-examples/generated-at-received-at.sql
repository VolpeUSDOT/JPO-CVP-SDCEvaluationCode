-- BSM and TIM Metadata RECORDGENERATEDAT vs ODERECEIVEDAT
-- WYDOT BSM and TIM messages include metadata section, appended by 
-- the Operational Data Environment (ODE) component (see 
-- https://dot-jpo.atlassian.net/wiki/spaces/CVPIL/pages/1052552/CV+PEP+Team+Documents 
-- for a full set of architecture documents).
-- Among others, there are 2 timestamps of interest present in this section:
-- recordGeneratedAt: Closest time to which the record was created by a Vehicle.
-- odeReceivedAt: Time ODE received the data in UTC format. This time is 
-- the closest to which the CV PEP system received the record.
-- Based on real-life conditions, odeReceivedAt may be days or even weeks after the recordGeneratedAt timestamp.
-- The following queries result in distribution of recordGeneratedAt by odeRecevedAt times

select SUBSTR(metadata.recordgeneratedat, 0, 10) as RECORDGENERATEDAT
, SUBSTR(metadata.odereceivedat, 0, 10) as ODERECEIVEDAT
, count(SUBSTR(metadata.odereceivedat, 0, 10)) as CNT
from wydot_bsm_v5
group by SUBSTR(metadata.odereceivedat, 0, 10)
, SUBSTR(metadata.recordgeneratedat, 0, 10)
order by RECORDGENERATEDAT limit 5;

select SUBSTR(metadata.recordgeneratedat, 0, 10) as RECORDGENERATEDAT
, SUBSTR(metadata.odereceivedat, 0, 10) as ODERECEIVEDAT
, count(SUBSTR(metadata.odereceivedat, 0, 10)) as CNT
from wydot_tim
group by SUBSTR(metadata.odereceivedat, 0, 10)
, SUBSTR(metadata.recordgeneratedat, 0, 10)
order by RECORDGENERATEDAT limit 10000;

select SUBSTR(metadatarecordgeneratedat, 0, 10) as RECORDGENERATEDAT
, SUBSTR(metadataodereceivedat, 0, 10) as ODERECEIVEDAT
, count(SUBSTR(metadataodereceivedat, 0, 10)) as CNT
from wydot_bsm_core
group by SUBSTR(metadataodereceivedat, 0, 10)
, SUBSTR(metadatarecordgeneratedat, 0, 10)
order by RECORDGENERATEDAT limit 5;

select SUBSTR(metadatarecordgeneratedat, 0, 10) as RECORDGENERATEDAT
, SUBSTR(metadataodereceivedat, 0, 10) as ODERECEIVEDAT
from wydot_bsm_core
where SUBSTR(metadatarecordgeneratedat, 0, 10) = '1902-02-20'
limit 5;

select count(*) from wydot_bsm_core where SUBSTR(metadatarecordgeneratedat, 0, 10) = '1902-02-20';



