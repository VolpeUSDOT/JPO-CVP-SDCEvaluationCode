----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from nyc_spat_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables:
--   nyc_spat_core
--   nyc_spat_intersections
--   nyc_spat_intersections_states
--   nyc_spat_intersections_states_statetimespeed
--   nyc_spat_intersections_states_maneuverassist
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create tables if needed
--------------------------------------------------
CREATE TABLE IF NOT EXISTS nyc_spat_core(
    spatid string,
    EVENTID string,
    EVENTTYPE string,
    SEQNUM int,
    SPATRECORDMSGHEADERMYRFLEVEL int,
    SPATRECORDMSGHEADERAUTHENTICATED boolean
);
    
CREATE TABLE IF NOT EXISTS nyc_spat_intersections(
    interid string,
    spatid string,
    INTERSECTIONID string,
    INTERSECTIONREVISION int,
    INTERSECTIONSTATUS string,
    INTERSECTIONTIME_SEC double
);

CREATE TABLE IF NOT EXISTS nyc_spat_intersections_states(
    stateid string,
    interid string,
    spatid string,
    SIGNALGROUP int
);

CREATE TABLE IF NOT EXISTS nyc_spat_intersections_states_statetimespeed(
    stateid string,
    interid string,
    spatid string,
    EVENTSTATE string,
    TIMINGCONFIDENCE int,
    TIMINGMAXENDTIME_S double,
    TIMINGMINENDTIME_S double,
    TIMINGLIKELYTIME_S double,
    TIMINGNEXTTIME_S double
);

CREATE TABLE IF NOT EXISTS nyc_spat_intersections_states_maneuverassist(
    stateid string,
    interid string,
    spatid string,
    CONNECTIONID int,
    QUEUELENGTH int,
    AVAILABLESTORAGELENGTH int,
    WAITONSTOP boolean,
    PEDBICYCLEDETECT boolean
);

--------------------------------------------------
-- insert data nyc_spat_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_spat_tmp;

CREATE TABLE nyc_spat_tmp  
    STORED AS ORC tblproperties("orc.compress"="Zlib") 
    AS SELECT reflect("java.util.UUID", "randomUUID") spatid, 
    * 
FROM nyc_spat_staging;

INSERT INTO TABLE nyc_spat_core
SELECT
    spatid,
    EVENTID AS EVENTID,
    EVENTTYPE AS EVENTTYPE,
    SEQNUM AS SEQNUM,
    SPATRECORD.MSGHEADER.MYRFLEVEL AS SPATRECORDMSGHEADERMYRFLEVEL,
    SPATRECORD.MSGHEADER.AUTHENTICATED AS SPATRECORDMSGHEADERAUTHENTICATED
FROM nyc_spat_tmp;

--------------------------------------------------
-- insert data nyc_spat_intersections_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_spat_intersections_tmp;

CREATE TABLE nyc_spat_intersections_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
    reflect("java.util.UUID","randomUUID") interid,
    spatid,
    intersections
FROM nyc_spat_tmp 
LATERAL VIEW explode(SPATRECORD.SPATMSG.INTERSECTIONS) intersectionsArray AS intersections;

INSERT INTO TABLE nyc_spat_intersections
SELECT 
    interid,
    spatid,
    intersections.ID.ID AS INTERSECTIONID,
    intersections.REVISION AS INTERSECTIONREVISION,
    intersections.STATUS AS INTERSECTIONSTATUS,
    intersections.TIME_SEC AS INTERSECTIONTIME_SEC
FROM nyc_spat_intersections_tmp;

--------------------------------------------------
-- insert data nyc_spat_intersections_states_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_spat_intersections_states_tmp;

CREATE TABLE nyc_spat_intersections_states_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
    reflect("java.util.UUID","randomUUID") stateid,
    interid,
    spatid,
    states
FROM nyc_spat_intersections_tmp 
LATERAL VIEW explode(intersections.STATES) statesArray AS states;

INSERT INTO TABLE nyc_spat_intersections_states
SELECT 
    stateid,
    interid,
    spatid,
    states.SIGNALGROUP AS SIGNALGROUP
FROM nyc_spat_intersections_states_tmp;

INSERT INTO TABLE nyc_spat_intersections_states_statetimespeed
SELECT 
    stateid,
    interid,
    spatid,
    sts.EVENTSTATE AS EVENTSTATE,
    sts.TIMING.CONFIDENCE AS TIMINGCONFIDENCE,
    sts.TIMING.MAXENDTIME_S AS TIMINGMAXENDTIME_S,
    sts.TIMING.MINENDTIME_S AS TIMINGMINENDTIME_S,
    sts.TIMING.LIKELYTIME_S AS TIMINGLIKELYTIME_S,
    sts.TIMING.NEXTTIME_S AS TIMINGNEXTTIME_S
FROM nyc_spat_intersections_states_tmp
LATERAL VIEW explode(states.STATETIMESPEED) stsArray as sts;

INSERT INTO TABLE nyc_spat_intersections_states_maneuverassist
SELECT 
    stateid,
    interid,
    spatid,
    mal.CONNECTIONID AS CONNECTIONID,
    mal.QUEUELENGTH AS QUEUELENGTH,
    mal.AVAILABLESTORAGELENGTH AS AVAILABLESTORAGELENGTH,
    mal.WAITONSTOP AS WAITONSTOP,
    mal.PEDBICYCLEDETECT AS PEDBICYCLEDETECT
FROM nyc_spat_intersections_states_tmp
LATERAL VIEW explode(states.MANEUVERASSISTLIST) malArray as mal;

--DROP temperary tables. 

DROP TABLE IF EXISTS nyc_spat_tmp;
DROP TABLE IF EXISTS nyc_spat_intersections_tmp;
DROP TABLE IF EXISTS nyc_spat_intersections_states_tmp;
