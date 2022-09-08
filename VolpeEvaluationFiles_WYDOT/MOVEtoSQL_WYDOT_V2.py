#!/usr/bin/env python
# coding: utf-8

# In[2]:


import PySDC
import datetime
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import sqlalchemy
import numpy as np
from shapely.geometry import LineString
from shapely import wkt
from pyodbc import ProgrammingError
from labellines import labelLine, labelLines
from tqdm.notebook import tqdm
import pickle

get_ipython().run_line_magic('matplotlib', 'notebook')

HiveConn = PySDC.connect_hive(host='hdfs-master.prod.sdc.dot.gov',
                            port=10000,
                            username='wchupp',
                            password='October/12/943',
                            configuration={'hive.resultset.use.unique.column.names':'false'})

MSSQLEngine = sqlalchemy.create_engine('mssql+pyodbc://' #Driver
                                       'hadoop:hadoop@' #Username:Password
                                       'ECSPWVOL01' #Server IP
                                       '/WYDOTDB_V2' #dbname
                                       '?driver=ODBC+Driver+17+for+SQL+Server')


# In[3]:


get_ipython().run_cell_magic('time', '', '# Get all of the Warnings\n#EventsAll = pd.read_sql("select * from default.wydot_alert_core \\\n#                      where metadatarecordgeneratedat BETWEEN \\\n#                      \'2022-01-01T00:00:00.00Z\' and \'2022-05-01T00:00:00.00Z\'",\n#                    con=HiveConn)\n\n#EventsAll.to_pickle(r\'C:\\Users\\wchupp.SDC\\Documents\\CVEval\\Wyoming\\EventsAllDataFrame\')\n\nEventsAll = pd.read_pickle(r\'C:\\Users\\wchupp.SDC\\Documents\\CVEval\\Wyoming\\EventsAllDataFrame\')')


# In[4]:


FCWAlerts = EventsAll.loc[EventsAll['payloadalert'].str.contains("FCW")].copy()
FCWAlerts.reset_index(inplace=True, drop=True)

FCWAlerts.rename(columns = {"metadatalogfilename":"LogFilename",
                            "metadatarecordtype":"RecordType",
                            "metadatareceivedmessagedetailslocationdatalatitude":"HVLat",
                            "metadatareceivedmessagedetailslocationdatalongitude":"HVLong",
                            "metadatareceivedmessagedetailslocationdataelevation":"HVElev",
                            "metadatareceivedmessagedetailslocationdataspeed":"HVSpeed",
                            "metadatareceivedmessagedetailslocationdataheading":"HVHeading",
                            "metadatapayloadtype":"PayloadType",
                            "metadataserialidstreamid":"StreamID",
                            "metadataserialidbundlesize":"BundleSize",
                            "metadataserialidbundleid":"BundleID",
                            "metadataserialidrecordid":"RecordID",
                            "metadataserialidserialnumber":"SerialNumber",
                            "metadataodereceivedat":"SDCRecievedAt",
                            "metadataschemaversion":"Version",
                            "metadatarecordgeneratedat":"AlertStartTime",
                            "metadatarecordgeneratedby":"GeneratedBy",
                            "metadatasanitized":"Sanitized",
                            "payloadalert":"Alert"}, inplace=True)

FCWAlerts.loc[~FCWAlerts['AlertStartTime'].str.contains("\."), 'AlertStartTime'] = FCWAlerts.loc[~FCWAlerts['AlertStartTime'].str.contains("\."), 'AlertStartTime'].str.replace('Z', '.000Z')


FCWAlerts['AlertStartTime'] = pd.to_datetime(FCWAlerts['AlertStartTime'], format='%Y-%m-%dT%H:%M:%S.%fZ')


# In[5]:


FCWAlerts.insert(1, 'HVTempID', '')

FCWAlerts['HVTempID'] = FCWAlerts['LogFilename'].str.extract(r'((?<=_)(?:[A-Fa-f0-9]{1,4}[:_][:_]?){1,7}[A-Fa-f0-9]{1,4})', 
                                                             expand = False)
FCWAlerts.sort_values(['HVTempID', 'AlertStartTime'], inplace=True)

FCWAlerts.reset_index(inplace=True, drop=True)

FCWAlerts


# In[6]:


indexes = FCWAlerts.index
FCWAlerts['Unique'] = True
for index in tqdm(indexes):
    if index == 0:
        continue
    if FCWAlerts.loc[index, 'HVTempID'] != FCWAlerts.loc[index-1, 'HVTempID']:
        continue
    diff = FCWAlerts.loc[index, 'AlertStartTime'] - FCWAlerts.loc[index-1, 'AlertStartTime']
    if diff.total_seconds() <= 30:
        FCWAlerts.loc[index, 'Unique'] = False

FCWAlerts


# In[ ]:


FCWAlertsUnique = FCWAlerts.loc[FCWAlerts['Unique']].copy()
FCWAlertsUnique.reset_index(inplace=True, drop=True)
FCWAlertsUnique.insert(2, 'VolpeID', 0)
FCWAlertsUnique['VolpeID'] = FCWAlertsUnique.index + 1
FCWAlertsUnique


# In[ ]:


HostVehIDs = FCWAlerts['HVTempID'].unique()

BSM = pd.DataFrame()

for index, alertRecord in tqdm(FCWAlertsUnique.iterrows(), total = len(FCWAlertsUnique)):
   
   bsmStart = alertRecord['AlertStartTime'] - pd.Timedelta(seconds=20)
   bsmEnd = alertRecord['AlertStartTime'] + pd.Timedelta(seconds=20)
   
   bsmStart = bsmStart.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3]+'Z'
   bsmEnd = bsmEnd.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3]+'Z'
   
   NewBSM = pd.read_sql("select * from volpeie.wydot_bsm_dataset \
                     where metadatalogfilename like '%{}%' and metadatarecordgeneratedat BETWEEN \
                     '{}' and '{}'".format(alertRecord['HVTempID'], bsmStart, bsmEnd),
               con=HiveConn)
   NewBSM.insert(1, 'VolpeID', 1)
   NewBSM['VolpeID'] = alertRecord['VolpeID']
   #NewBSM = pd.read_sql("select * from volpeie.wydot_bsm_dataset where metadatalogfilename like '%{}%'".format(ID), con=HiveConn)
   BSM = BSM.append(NewBSM)
   print(len(BSM))
    
#BSM.to_pickle(r'C:\Users\wchupp.SDC\Documents\CVEval\Wyoming\FCWBSM_DataFrame')

#BSM = pd.read_pickle(r'C:\Users\wchupp.SDC\Documents\CVEval\Wyoming\FCWBSM_DataFrame')


# In[ ]:


BSM.rename(columns = {
"bsmid":"bsmid",
"metadatabsmsource":"VehicleRole",
"metadatalogfilename":"LogFilename",
"metadatarecordtype":"RecordType",
"metadatapayloadtype":"PayloadType",
"metadatastreamid":"StreamID",
"metadatabundlesize":"BundleSize",
"metadatabundleid":"BundleID",
"metadatarecordid":"RecordID",
"metadataserialnumber":"SerialNumber",
"metadataodereceivedat":"RecievedAt",
"metadataschemaversion":"SchemaVersion",
"metadatarecordgeneratedat":"DateTime",
"metadatarecordgeneratedby":"GeneratedBy",
"metadatavalidsignature":"ValidSignature",
"metadatasecurityresultcode":"SecurityResultCode",
"metadatareceivedmessagedetailslocationdatalatitude":"HVLatitude",
"metadatareceivedmessagedetailslocationdatalongitude":"HVLongitude",
"metadatareceivedmessagedetailslocationdataelevation":"HVElevation",
"metadatareceivedmessagedetailslocationdataspeed":"HVSpeed",
"metadatareceivedmessagedetailslocationdataheading":"HVHeading",
"metadatareceivedmessagedetailsrxsource":"RXSource",
"metadatasanitized":"Sanitized",
"coredatamsgcnt":"MsgCount",
"coredataid":"VehicleTempID",
"coredatasecmark":"SecMark",
"coredatalatitude":"Latitude",
"coredatalongitude":"Longitude",
"coredataelevation":"Elevation",
"coredataaccelyaw":"YawRate",
"coredataaccellat":"ALat",
"coredataaccellong":"ALong",
"coredataaccelvert":"AVert",
"coredataaccuracysemimajor":"SemiMajorAccuracy",
"coredataaccuracysemiminor":"SemiMinorAccuracy",
"coredatatransmission":"Transmission",
"coredataspeed":"Speed",
"coredataheading":"Heading",
"coredatawheelbrakesleftfront":"BrakesLeftFront",
"coredatawheelbrakesrightfront":"BrakesRightFront",
"coredatawheelbrakesunavailable":"BrakesUnavailable",
"coredatawheelbrakesleftrear":"BrakesLeftRear",
"coredatawheelbrakesrightrear":"BrakesRightRear",
"coredatabrakestraction":"BrakesTraction",
"coredatabrakesabs":"BrakesABS",
"coredatabrakesscs":"BrakesSCS",
"coredatabrakesbrakeboost":"BrakesBoost",
"coredatabrakesauxbrakes":"AuxBrakes",
"coredatasizelength":"Length",
"coredatasizewidth":"Width"}, 
inplace=True)

BSM.loc[~BSM['DateTime'].str.contains("\."), 'DateTime'] = BSM.loc[~BSM['DateTime'].str.contains("\."), 'DateTime'].str.replace('Z', '.000Z')

BSM['DateTime'] = pd.to_datetime(BSM['DateTime'], format='%Y-%m-%dT%H:%M:%S.%fZ')

BSM['DateTime'] = BSM['DateTime'] + ((round(BSM['DateTime'].dt.microsecond/int(100000), 0).astype(int))*100000 
                  - BSM['DateTime'].dt.microsecond).apply(lambda x: datetime.timedelta(microseconds=x))

HVBSM = BSM.loc[BSM['VehicleRole']=='EV'].copy()
RVBSM = BSM.loc[BSM['VehicleRole']=='RV'].copy()

HVBSM['DateTime'] = HVBSM['DateTime'].dt.round('ms')
RVBSM['DateTime'] = RVBSM['DateTime'].dt.round('ms')

HVBSM.to_sql('HostVehicleData', if_exists='replace', con=MSSQLEngine, index=False)
RVBSM.to_sql('TargetVehicleData', if_exists='replace', con=MSSQLEngine, index=False)

FCWAlertsUnique.to_sql('FCWAlerts', if_exists='replace', con=MSSQLEngine, index=False)


# In[ ]:


TIMAlerts = EventsAll.loc[EventsAll['payloadalert'].str.contains("TIM")].copy()


TIMAlerts.reset_index(inplace=True, drop=True)

TIMAlerts.rename(columns = {"metadatalogfilename":"LogFilename",
                            "metadatarecordtype":"RecordType",
                            "metadatareceivedmessagedetailslocationdatalatitude":"HVLat",
                            "metadatareceivedmessagedetailslocationdatalongitude":"HVLong",
                            "metadatareceivedmessagedetailslocationdataelevation":"HVElev",
                            "metadatareceivedmessagedetailslocationdataspeed":"HVSpeed",
                            "metadatareceivedmessagedetailslocationdataheading":"HVHeading",
                            "metadatapayloadtype":"PayloadType",
                            "metadataserialidstreamid":"StreamID",
                            "metadataserialidbundlesize":"BundleSize",
                            "metadataserialidbundleid":"BundleID",
                            "metadataserialidrecordid":"RecordID",
                            "metadataserialidserialnumber":"SerialNumber",
                            "metadataodereceivedat":"SDCRecievedAt",
                            "metadataschemaversion":"Version",
                            "metadatarecordgeneratedat":"AlertStartTime",
                            "metadatarecordgeneratedby":"GeneratedBy",
                            "metadatasanitized":"Sanitized",
                            "payloadalert":"Alert"}, inplace=True)

TIMAlerts.loc[~TIMAlerts['AlertStartTime'].str.contains("\."), 'AlertStartTime'] = TIMAlerts.loc[~TIMAlerts['AlertStartTime'].str.contains("\."), 'AlertStartTime'].str.replace('Z', '.000Z')


TIMAlerts['AlertStartTime'] = pd.to_datetime(TIMAlerts['AlertStartTime'], format='%Y-%m-%dT%H:%M:%S.%fZ')

TIMAlerts.insert(1, 'HVTempID', '')

TIMAlerts['HVTempID'] = TIMAlerts['LogFilename'].str.extract(r'((?<=_)(?:[A-Fa-f0-9]{1,4}[:_][:_]?){1,7}[A-Fa-f0-9]{1,4})', 
                                                             expand = False)
ITISCodes = pd.read_excel(r'C:\Users\wchupp.SDC\Documents\CVEval\Wyoming\ITISCodes.xlsx')
ITISCodes['Code'] = ITISCodes['Code'].astype(str).str.replace("_", "")
ITISCodes.index = ITISCodes['Code']

TIMAlerts['DriverAlertMessage'] = pd.Series([','.join(x[4:]) for x in TIMAlerts['Alert'].str.split(',')])

TIMAlerts = TIMAlerts.join(ITISCodes, on='DriverAlertMessage')

TIMAlerts.sort_values(['HVTempID', 'DriverAlertMessage', 'AlertStartTime'], inplace=True)

TIMAlerts.reset_index(inplace=True, drop=True)


# In[ ]:


indexes = TIMAlerts.index
TIMAlerts['Unique'] = True
for index in tqdm(indexes):
    if index == 0:
        continue
    if TIMAlerts.loc[index, 'HVTempID'] != TIMAlerts.loc[index-1, 'HVTempID'] or        TIMAlerts.loc[index, 'DriverAlertMessage'] != TIMAlerts.loc[index-1, 'DriverAlertMessage']:
        continue
    diff = TIMAlerts.loc[index, 'AlertStartTime'] - TIMAlerts.loc[index-1, 'AlertStartTime']
    if diff.total_seconds() <= 30:
        TIMAlerts.loc[index, 'Unique'] = False

TIMAlertsUniques = TIMAlerts.loc[TIMAlerts['Unique']].copy()
TIMAlertsUniques.to_sql('TIMAlerts', if_exists='replace', con=MSSQLEngine, index=False)


# In[23]:


SpeedSensors = pd.read_sql("select * from wydot_speed_sensors_index", con = HiveConn)

SpeedSensors.to_sql('SpeedSensors', if_exists='replace', con=MSSQLEngine, index=False)


# In[2]:


# Get all of the Warnings

#SpeedBefore = pd.read_sql(" \
#select \
#* \
#from wydot_speed_processed \
#where year(from_unixtime(unix_timestamp(date_time, 'MM/dd/yyyy HH:mm:ss'))) = 2019 and \
#month(from_unixtime(unix_timestamp(date_time, 'MM/dd/yyyy HH:mm:ss'))) in (1, 2, 3, 4) ",
#                    con=HiveConn)

#SpeedBefore.to_pickle(r'C:\Users\wchupp.SDC\Documents\CVEval\Wyoming\SpeedBefore_DataFrame')
SpeedBefore = pd.read_pickle(r'C:\Users\wchupp.SDC\Documents\CVEval\Wyoming\SpeedBefore_DataFrame')


# In[20]:


SpeedAfter = pd.read_sql(" select * from wydot_speed_processed where year(from_unixtime(unix_timestamp(date_time, 'MM/dd/yyyy HH:mm:ss'))) = 2022 and month(from_unixtime(unix_timestamp(date_time, 'MM/dd/yyyy HH:mm:ss'))) in (1, 2, 3, 4) ",
                    con=HiveConn, chunksize=100000)



i = 0
for chunk in tqdm(SpeedAfter, total = 69975307//100000):
    chunk['date_time'] = pd.to_datetime(chunk['date_time'], format='%m/%d/%Y %H:%M:%S')
    
    if i == 0:
        chunk.to_sql('SpeedAfter', if_exists='replace', con=MSSQLEngine, index=False)
    else:
        chunk.to_sql('SpeedAfter', if_exists='append', con=MSSQLEngine, index=False)
    
    i+=1


# In[28]:


SpeedBefore = pd.read_sql(" select * from wydot_speed_processed where year(from_unixtime(unix_timestamp(date_time, 'MM/dd/yyyy HH:mm:ss'))) = 2017 and month(from_unixtime(unix_timestamp(date_time, 'MM/dd/yyyy HH:mm:ss'))) in (1, 2, 3, 4) ",
                    con=HiveConn, chunksize=100000)



i = 0
for chunk in tqdm(SpeedBefore, total = 20043234//100000):
    chunk['date_time'] = pd.to_datetime(chunk['date_time'], format='%m/%d/%Y %H:%M:%S')
    
    if i == 0:
        chunk.to_sql('SpeedBefore_2017', if_exists='replace', con=MSSQLEngine, index=False)
    else:
        chunk.to_sql('SpeedBefore_2017', if_exists='append', con=MSSQLEngine, index=False)
    
    i+=1


# In[7]:


SpeedBefore['date_time'] = pd.to_datetime(SpeedBefore['date_time'], format='%m/%d/%Y %H:%M:%S')

for i, g in tqdm(SpeedBefore.groupby(np.arange(len(SpeedBefore))//100000)):
    if i == 0:
        g.to_sql('SpeedBefore', if_exists='replace', con=MSSQLEngine, index=False)
    else:
        g.to_sql('SpeedBefore', if_exists='append', con=MSSQLEngine, index=False)


# In[26]:


VSL = pd.read_sql("Select * from wydot_vsl", con=HiveConn, chunksize=100000)

i = 0
for chunk in tqdm(VSL, total = 5232157//100000):
    chunk['local'] = chunk['local'].str.replace('-06:00', '')
    chunk['local'] = chunk['local'].str.replace('-07:00', '')
    chunk['local'] = pd.to_datetime(chunk['local'], format='%Y-%m-%dT%H:%M:%S')
    
    if i == 0:
        chunk.to_sql('VSL', if_exists='replace', con=MSSQLEngine, index=False)
    else:
        chunk.to_sql('VSL', if_exists='append', con=MSSQLEngine, index=False)
    
    i+=1
