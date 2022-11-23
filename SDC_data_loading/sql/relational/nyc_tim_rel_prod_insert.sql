----------------------------------------------------------------------------------------------------
-- This script inserts relational data into relational tables from nyc_tim_staging table (which has nested JSON data).
-- Two temporary tables are deleted at the end of the script.
-- Relational tables:
--   nyc_tim_core
--   nyc_tim_dataframes
--   nyc_tim_dataframes_content
----------------------------------------------------------------------------------------------------

--------------------------------------------------
-- create tables if needed
--------------------------------------------------
CREATE TABLE IF NOT EXISTS nyc_tim_core(
    timid string,
    EVENTID string,
    EVENTTYPE string,
    SEQNUM int,
    TIMRECORDMSGHEADERMYRFLEVEL int,
    TIMRECORDMSGHEADERAUTHENTICATED boolean,
    TIMRECORDTIMMSGMSGCNT int,
    TIMRECORDTIMMSGPACKETID int
);
    
CREATE TABLE IF NOT EXISTS nyc_tim_dataframes(
    dfid string,
    timid string,
    SSPTIMRIGHTS int,
    FRAMETYPE string,
    MSGIDROADSIGNIDVIEWANGLE string,
    MSGIDROADSIGNIDMUTCDCODE string,
    PRIORITY int,
    SSPLOCATIONRIGHTS int,
    SSPMSGRIGHTS1 int,
    SSPMSGRIGHTS2 int
);

CREATE TABLE IF NOT EXISTS nyc_tim_dataframes_content(
    dfid string,
    timid string,
    ADVISORYITEMITIS int,
    ADVISORYITEMTEXT string
);

--------------------------------------------------
-- insert data nyc_tim_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_tim_tmp;

CREATE TABLE nyc_tim_tmp  
    STORED AS ORC tblproperties("orc.compress"="Zlib") 
    AS SELECT reflect("java.util.UUID", "randomUUID") timid, 
    * 
FROM nyc_tim_staging;

INSERT INTO TABLE nyc_tim_core
SELECT
    timid,
    EVENTID AS EVENTID,
    EVENTTYPE AS EVENTTYPE,
    SEQNUM AS SEQNUM,
    TIMRECORD.MSGHEADER.MYRFLEVEL AS MAPRECACTMSGHEADERMYRFLEVEL,
    TIMRECORD.MSGHEADER.AUTHENTICATED AS MAPRECACTMSGHEADERAUTHENTICATED,
    TIMRECORD.TIMMSG.MSGCNT AS TIMRECORDTIMMSGMSGCNT,
    TIMRECORD.TIMMSG.PACKETID AS TIMRECORDTIMMSGPACKETID
FROM nyc_tim_tmp;

--------------------------------------------------
-- insert data nyc_tim_dataframes_tmp
--------------------------------------------------
DROP TABLE IF EXISTS nyc_tim_dataframes_tmp;

CREATE TABLE nyc_tim_dataframes_tmp 
STORED AS ORC tblproperties ("orc.compress" = "Zlib")
AS SELECT 
    reflect("java.util.UUID","randomUUID") dfid,
    timid,
    dataframes
FROM nyc_tim_tmp 
LATERAL VIEW explode(TIMRECORD.TIMMSG.DATAFRAMES) dataframesArray AS dataframes;

INSERT INTO TABLE nyc_tim_dataframes
SELECT 
    dfid,
    timid,
    dataframes.SSPTIMRIGHTS AS SSPTIMRIGHTS,
    dataframes.FRAMETYPE AS FRAMETYPE,
    dataframes.MSGID.ROADSIGNID.VIEWANGLE AS MSGIDROADSIGNIDVIEWANGLE,
    dataframes.MSGID.ROADSIGNID.MUTCDCODE AS MSGIDROADSIGNIDMUTCDCODE,
    dataframes.PRIORITY AS PRIORITY,
    dataframes.SSPLOCATIONRIGHTS AS SSPLOCATIONRIGHTS,
    dataframes.SSPMSGRIGHTS1 AS SSPMSGRIGHTS1,
    dataframes.SSPMSGRIGHTS2 AS SSPMSGRIGHTS2
FROM nyc_tim_dataframes_tmp;

INSERT INTO TABLE nyc_tim_dataframes_content
SELECT 
    dfid,
    timid,
    content.ITEM.ITIS AS ADVISORYITEMITIS,
    content.ITEM.TEXT AS ADVISORYITEMTEXT
FROM nyc_tim_dataframes_tmp
LATERAL VIEW explode(dataframes.CONTENT.ADVISORY) contentArray as content;

--DROP temperary tables. 

DROP TABLE IF EXISTS nyc_tim_tmp;
DROP TABLE IF EXISTS nyc_tim_dataframes_tmp;
