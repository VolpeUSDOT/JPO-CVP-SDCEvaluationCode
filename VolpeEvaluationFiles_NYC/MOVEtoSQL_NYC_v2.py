#!/usr/bin/env python
# coding: utf-8

# In[1]:


import PySDC
import credentials
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

get_ipython().run_line_magic('matplotlib', 'notebook')

HiveConn = PySDC.connect_hive(host='hdfs-master.prod.sdc.dot.gov',
                            port=10000,
                            username='', ## Set this value
                            password='', ## Set this value
                            configuration={'hive.resultset.use.unique.column.names':'false'})

MSSQLEngine = sqlalchemy.create_engine('mssql+pyodbc://' #Driver
                                       'hadoop:hadoop@' #Username:Password
                                       'ECSPWVOL01' #Server IP
                                       '/NYCDB' #dbname
                                       '?driver=ODBC+Driver+17+for+SQL+Server')


# In[2]:


EventTableNames = pd.read_sql('show tables', con=HiveConn)

EventTableNames = EventTableNames.loc[EventTableNames['tab_name'].str.contains('^nyc_event.+_core$')]['tab_name']

EventTableNames = EventTableNames.str.replace('nyc_event', '').str.replace('_core', '')


# In[3]:


# Get all of the Warnings
AllEvents = pd.DataFrame()

eventInfo = []

for tab_name in EventTableNames:
    ExistingEvents = pd.DataFrame(columns=['eventid', 'VolpeID']) #pd.read_sql("select eventid, VolpeID from AllWarningEvent where WarningType = '{}'".format(tab_name), con=MSSQLEngine)
    ExistingEvents = ExistingEvents.append({'eventid':'1'}, ignore_index=True)
    ExistingEvents['eventid'] = "'" + ExistingEvents['eventid'] + "'"
    ExistingEvents
    eventInstring = '(' + ExistingEvents['eventid'].str.cat(sep = ', ') + ')'
    
    #if tab_name == "bsw": continue
    print('transfering {} data'.format(tab_name))
    
    print('Selecting all but {} events'.format(len(ExistingEvents)-1))
    
    Events = pd.read_sql("select * from default.nyc_event{}_core where eventid not in {}".format(tab_name, eventInstring),
                         con=HiveConn)
    
    Events.rename(columns = {"eventheaderlocationsource": "LocationSource",
                            "eventheaderasdfirmwareversion": "Version",
                            "eventheadereventalertactive": "Active",
                            "eventheadereventalertsent": "Sent",
                            "eventheadereventalertheard": "Heard",
                            "eventheaderhostvehid": "HostVehID",
                            "eventheadertargetvehid": "TargetID",
                            "eventheadertriggerhvseqnum": "SeqNumHV",
                            "eventheadertriggertvseqnum": "SeqNumTV",
                            "eventheadereventtype": "WarningType",
                            "eventheaderparametersrecordingroi": "ROI",
                            "eventheaderparameterstimerecordbefore": "TimeRecBefore",
                            "eventheaderparameterstimerecordfollow": "TimeRecordFollow",
                            "eventheaderparameterstimerecordresolution": "DataResolution",
                            "eventheaderparametersminspdthreshold": "minSpdThreshold",
                            "eventheaderparameterstimetocrash": "TTC",
                            "eventheadereventstatus": "EventStatus",
                            "eventheadereventtimebin": "TimeBin",
                            "eventheadereventlocationbin": "LocationBin",
                            "eventheaderweathercondition": "WeatherCond",
                            "eventheaderairtempurature": "AirTempurature",
                            "eventheaderprecipitation1hr": "Precipitation1hr",
                            "eventheaderwindspeed": "WindSpeed",
                            "eventheaderparametersexcessivecurvespd": "ExcessiveCurveSpeed",
                            "eventheaderparametersexcessivecurvespdtime": "ExcessiveCurveSpeedTime",
                            "eventheaderparametersmincurvespd": "minCurveSpeed",
                            "eventheadergrpid": "GrpID",
                            "eventheaderparameterspostedheightlimit": "HeightLimit",
                            "eventheaderparameterspostedsizelimit": "SizeLimit",
                            "eventheaderparametersexcessivespd": "ExcessiveSpeed",
                            "eventheaderparametersexcessivespdtime": "ExcessiveSpeedTime",
                            "eventheaderparametersexcessivezonespd": "ExcessiveZoneSpeed",
                            "eventheaderparametersexcessivezonespdtime": "ExcessiveZoneSpeedTime"}, inplace=True)
    
    maxVolpeID = ExistingEvents['VolpeID'].max()
    if pd.isna(maxVolpeID):
        maxVolpeID = 0
    print(maxVolpeID)
    Events['VolpeID'] = [i for i in range(int(maxVolpeID)+1,int(maxVolpeID)+len(Events)+1)]
    Events['dummytime'] = [datetime.datetime(year = int(tb.split('-')[0])%2000 + 2000, month = int(tb.split('-')[1]), day = 10, hour=12)                            for tb in Events['TimeBin']]
    
    Events['X'] = 0
    Events['Y'] = 0
    
    eventInfo.extend([(vID, eID, dt) for vID, eID, dt in zip(Events['VolpeID'], Events['eventid'], Events['dummytime'])])
    AllEvents = pd.concat([AllEvents, Events])


# In[4]:


print("inserting {} events".format(len(AllEvents)))
AllEvents.to_sql('AllWarningEvent', if_exists='replace', con=MSSQLEngine, index=False)
eventInfo = pd.DataFrame(eventInfo)


# In[5]:


del AllEvents


# In[6]:


ExistingBSM = pd.DataFrame(columns = ['EventID']) #pd.read_sql('select EventID from HostVehicleData group by EventID', con=MSSQLEngine)

count = 0
for i, g in tqdm(eventInfo.groupby(np.arange(len(eventInfo))//1000)):
    g[1] = "'" + g[1] + "'"
    eventInstring = '(' + g[1].str.cat(sep = ', ') + ')'
    BSMs = pd.read_sql("select b.*,                             p2.classification class, p2.vehicledataheight height, p2.vehicledatamass mass                             from default.nyc_bsm_core b                             left join (select * from nyc_bsm_partii where id = 2) p2                             on b.bsmid = p2.bsmid                             where eventid in {}".format(eventInstring), con=HiveConn)

    BSMs.rename(columns = {'bsmid': 'BSMID',
                        'vehiclerole': 'Role',
                        'eventid': 'EventID',
                        'eventtype': 'EventType',
                        'eventmsgseqnum': 'SeqNum',
                        'bsmrecordmsgheadermyrflevel': 'MyRFLevel',
                        'bsmrecordmsgheaderauthenticated': 'Authenticated',
                        'bsmrecordbsmmsgcoredatamsgcnt': 'MsgCnt',
                        'bsmrecordbsmmsgcoredataid': 'VehicleID',
                        'bsmrecordbsmmsgcoredataaccuracysemimajor': 'AccuracySemiMajor',
                        'bsmrecordbsmmsgcoredataaccuracysemiminor': 'AccuracySemiMinor',
                        'bsmrecordbsmmsgcoredataaccuracyorientation': 'AccuracyOrientation',
                        'bsmrecordbsmmsgcoredatatransmission': 'Transmission',
                        'bsmrecordbsmmsgcoredataangle': 'WheelAngle',
                        'bsmrecordbsmmsgcoredataaccelsetlong_mpss': 'Along',
                        'bsmrecordbsmmsgcoredataaccelsetlat_mpss': 'Alat',
                        'bsmrecordbsmmsgcoredataaccelsetvert_mpss': 'Az',
                        'bsmrecordbsmmsgcoredataaccelsetyaw_dps': 'Yaw',
                        'bsmrecordbsmmsgcoredatabrakeswheelbrakes': 'Brake',
                        'bsmrecordbsmmsgcoredatabrakestraction': 'BrakeTraction',
                        'bsmrecordbsmmsgcoredatabrakesabs': 'BrakeABS',
                        'bsmrecordbsmmsgcoredatabrakesscs': 'BrakeSSCS',
                        'bsmrecordbsmmsgcoredatabrakesbrakeboost': 'BrakeBoos',
                        'bsmrecordbsmmsgcoredatabrakesauxbrakes': 'BrakeAUX',
                        'bsmrecordbsmmsgcoredatasizewidth': 'Width',
                        'bsmrecordbsmmsgcoredatasizelength': 'Length',
                        'bsmrecordbsmmsgcoredatax_m': 'X',
                        'bsmrecordbsmmsgcoredatay_m': 'Y',
                        'bsmrecordbsmmsgcoredataz_m': 'Z',
                        'bsmrecordbsmmsgcoredatat_s': 'Time',
                        'bsmrecordbsmmsgcoredataspeed_mps': 'Speed',
                        'bsmrecordbsmmsgcoredataheading_deg': 'Heading'}, inplace = True)

    print(len(BSMs))

    mergedBSMs = pd.merge(BSMs, eventInfo, how='inner', left_on=['EventID'], right_on=[1])

    #del BSMs

    mergedBSMs.rename(columns={0:'VolpeID', 2:'dummytime'}, inplace=True)

    mergedBSMs.drop(columns = [1], inplace=True)

    mergedBSMs['dummytime'] = [dt + datetime.timedelta(seconds=s) for dt, s in zip(mergedBSMs['dummytime'], mergedBSMs['Time'])]
    mergedBSMs['Xdeg'] = mergedBSMs['X'].apply(lambda x: x* 9.01E-6)
    mergedBSMs['Ydeg'] = mergedBSMs['Y'].apply(lambda x: x* 9.01E-6)

    xMin = mergedBSMs.groupby(['EventID']).min('Xdeg').reset_index()[['EventID', 'Xdeg']].rename(columns={'Xdeg': 'XMin'})
    yMin = mergedBSMs.groupby(['EventID']).min('Ydeg').reset_index()[['EventID', 'Ydeg']].rename(columns={'Ydeg': 'YMin'})

    minLocs = pd.merge(xMin, yMin, on = 'EventID')

    mergedBSMsCorrectedLocs = pd.merge(mergedBSMs, minLocs, on='EventID')

    #del mergedBSMs
    
    mergedBSMsCorrectedLocs.loc[:, ['Xdeg']] = mergedBSMsCorrectedLocs['Xdeg'] - mergedBSMsCorrectedLocs['XMin'] + 0.000001
    mergedBSMsCorrectedLocs.loc[:, ['Ydeg']] = mergedBSMsCorrectedLocs['Ydeg'] - mergedBSMsCorrectedLocs['YMin'] + 0.000001
    
    mergedBSMsCorrectedLocs.drop(labels=['XMin', 'YMin'], axis=1, inplace=True)
    
    hostBSMs = mergedBSMsCorrectedLocs.loc[mergedBSMsCorrectedLocs['Role']=='host']
    hostBSMs.rename(columns={'VehicleID': 'hostVehicleID'}, inplace=True)
    targetBSMs = mergedBSMsCorrectedLocs.loc[mergedBSMsCorrectedLocs['Role']=='target']
    targetBSMs.rename(columns={'VehicleID': 'remoteVehicleID'}, inplace=True)
    
    #del mergedBSMsCorrectedLocs
    print('Inserting {} Host BSMs'.format(len(hostBSMs)))
    if count==0:    
        hostBSMs.to_sql('HostVehicleData', if_exists='replace', con=MSSQLEngine, index=False)
    else:
        hostBSMs.to_sql('HostVehicleData', if_exists='append', con=MSSQLEngine, index=False)

    print('Inserting {} Target BSMs'.format(len(targetBSMs)))
    if count==0:
        targetBSMs.to_sql('TargetVehicleData', if_exists='replace', con=MSSQLEngine, index=False)
    else:
        targetBSMs.to_sql('TargetVehicleData', if_exists='append', con=MSSQLEngine, index=False)
    count +=1

    print("Done")


# In[8]:


Maps = pd.read_sql("select * from default.nyc_map_core", con=HiveConn)
Maps_ints = pd.read_sql("select * from default.nyc_map_intersections", con=HiveConn)
Maps_laneset = pd.read_sql("select * from default.nyc_map_intersections_laneset", con=HiveConn)
Maps_connects = pd.read_sql("select * from default.nyc_map_intersections_laneset_connectsto", con=HiveConn)
Maps_nodes = pd.read_sql("select * from default.nyc_map_intersections_laneset_nodes", con=HiveConn)

Maps_nodes['nodex'] = Maps_nodes[['deltanodexy1_x','deltanodexy2_x',
                                    'deltanodexy3_x','deltanodexy4_x',
                                    'deltanodexy5_x','deltanodexy6_x']].aggregate('max', axis=1)

Maps_nodes['nodey'] = Maps_nodes[['deltanodexy1_y', 'deltanodexy2_y',
                                    'deltanodexy3_y', 'deltanodexy4_y',
                                    'deltanodexy5_y', 'deltanodexy6_y']].aggregate('max', axis=1)

Maps_nodes_single = Maps_nodes.drop(columns = ['deltanodexy1_x','deltanodexy2_x',
                                    'deltanodexy3_x','deltanodexy4_x',
                                    'deltanodexy5_x','deltanodexy6_x', 
                                    'deltanodexy1_y', 'deltanodexy2_y',
                                    'deltanodexy3_y', 'deltanodexy4_y',
                                    'deltanodexy5_y', 'deltanodexy6_y'])



nodes_combined = []
curLaneID = ''
nodelist = []
lastNode = (0, 0)
for index, row in Maps_nodes_single.iterrows():
    if curLaneID != row['laneid'] and curLaneID != '': 
        toApp = {'laneid': curLaneID, 'nodeList':nodelist}
        nodes_combined.append(toApp)
        nodelist = []
        lastNode = (0,0)
    
    curLaneID = row['laneid']
    lastNode = (lastNode[0]+row['nodex']/100, lastNode[1]+row['nodey']/100)
    nodelist.append(lastNode)
    
nodes_combined = pd.DataFrame(nodes_combined)

maps_joined = pd.merge(Maps, Maps_ints, on=["mapid"])
maps_joined = pd.merge(maps_joined, Maps_laneset, on=["interid"])
maps_joined = pd.merge(maps_joined, Maps_connects, on=["laneid"])
maps_joined = pd.merge(maps_joined, nodes_combined, on=["laneid"])

maps_joined.rename(columns = {'interid_x': 'interid',
                            'intersectionid': 'intersectionid',
                            'intersectionrefpointx_m': 'ReferencePoint_X',
                            'intersectionrefpointy_m': 'ReferencePoint_Y',
                            'intersectionrefpointz_m': 'ReferencePoint_Z',
                            'intersectionlanewidth': 'lanewidth'}, inplace = True)

maps_joined = maps_joined[['eventid',
                            'eventtype',
                            'mapid',
                            'interid',
                            'intersectionid',
                            'ReferencePoint_X',
                            'ReferencePoint_Y',
                            'ReferencePoint_Z',
                            'lanewidth',
                            'lanesetlaneid',
                            'signalgroup',
                            'connectionid',
                            'nodeList']]

maps_joined['nodeList'] = [LineString([(refx+n[0], refy+n[1]) for n in nodes]).wkt 
                            for refx, refy, nodes in 
                            zip(maps_joined['ReferencePoint_X'], maps_joined['ReferencePoint_Y'], maps_joined['nodeList'])]

maps_joined.to_sql(name='MAPLaneGeometries', if_exists='replace', con=MSSQLEngine)


# In[9]:


query = "select b.*,                             p2.classification class, p2.vehicledataheight height, p2.vehicledatamass mass                             from default.nyc_bsm_core b                             join nyc_bsm_partii p2                             on b.bsmid = p2.bsmid                             where p2.classification is not null and eventid in {}".format(eventInstring)
query


# In[10]:


maps_joined['eventid'].unique()


# In[11]:


toPlot = maps_joined.loc[maps_joined['eventid']=='780d4a73-5103-4ac6-9099-4a30e714f3fe']
xVals = []

for index, row in toPlot.iterrows():
    x, y = wkt.loads(row['nodeList']).xy
    rx = row['ReferencePoint_X']
    ry = row['ReferencePoint_Y']
    plt.plot(x, y, 'b.-')
    xVals.append(sum(x)/len(x))
    plt.plot(x, y, 'gx')

labelLines(plt.gca().get_lines(), fontsize = 8, xvals=xVals)
plt.axis('equal')
plt.show()


# In[12]:


Spats = pd.read_sql("select * from default.nyc_spat_core", con=HiveConn)
Spats_ints = pd.read_sql("select * from default.nyc_spat_intersections", con=HiveConn)
Spats_states = pd.read_sql("select * from default.nyc_spat_intersections_states", con=HiveConn)
Spats_mans = pd.read_sql("select * from default.nyc_spat_intersections_states_maneuverassist", con=HiveConn)
Spats_statetimespeed = pd.read_sql("select * from default.nyc_spat_intersections_states_statetimespeed", con=HiveConn)

Spats_joined = pd.merge(Spats, Spats_ints, on=['spatid'])
Spats_joined = pd.merge(Spats_joined, Spats_states, on=['interid'])
Spats_joined = pd.merge(Spats_joined, Spats_statetimespeed, on=['stateid'])
Spats_joined = pd.merge(Spats_joined, Spats_mans, how='left', on=['stateid'])
Spats_final = Spats_joined[['eventid', 'eventtype', 'spatid_x', 'interid_x', 'intersectiontime_sec', 'intersectionid',                             'signalgroup', 'connectionid', 'eventstate']]

Spats_final = Spats_final.rename(columns = {'eventid':'EventID', 'eventtype':'EventType','spatid_x':'SpatID', 'interid_x':'InterID', 'intersectiontime_sec':'Time', 'eventstate':'SignalState'})

Spats_final['Time'] = Spats_final['Time'].round(1)

Spats_final.to_sql(name='SPaTSignal_TimeStates', if_exists='replace', con=MSSQLEngine)


# In[13]:


Spats_final[0:50]


# In[ ]:


x

