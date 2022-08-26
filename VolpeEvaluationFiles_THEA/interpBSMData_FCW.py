# -*- coding: utf-8 -*-
"""
Created on Thu Dec  5 16:40:22 2019

@author: wchupp
"""

import sqlalchemy
import pandas
import matplotlib.pyplot as plt
import datetime
import scipy.interpolate as interp
from scipy import arange
from calendar import timegm

MSSQLEngine = sqlalchemy.create_engine('mssql+pyodbc://' #Driver
                                       '@' #Username:Password
                                       '172.18.33.43' #Server IP
                                       '/THEADB' #dbname
                                       '?driver=ODBC+Driver+17+for+SQL+Server&'
                                       'trusted_connection=yes') #driver name

###############################################
###############################################
# Use This to decide which warning type and which warning(s) to choose

eventTableName = 'thea_warningfcw_core'
eventTimestampString = "metadataloggeneratedat > '2019-03-01 00:00:00.000' and metadataloggeneratedat < '2020-03-16 00:00:00.000'"

eventQueryString = 'select * from THEADB.dbo.{0} \
                    where {1}'.format(eventTableName, eventTimestampString)

idColumnName = 'fcwid'

###############################################
###############################################

eventRecords = pandas.read_sql(eventQueryString, con=MSSQLEngine)
eventRecords.drop_duplicates(subset=['metadataloggeneratedat', 'hvbsmid', 'rvbsmid', 'hvbsmlat', 'hvbsmlong', 'rvbsmlat', 'rvbsmlong'], inplace=True)
eventRecords.sort_values(by=['metadataloggeneratedat'], inplace=True)
eventRecords.reset_index(inplace=True)
eventRecords.insert(0, 'eventID', eventRecords.index+1)
eventRecords.drop(columns=['fcwid', 'level_0', 'index'], inplace=True)
eventRecords['rvbsmid'] = eventRecords['rvbsmid'].str.replace('"', '')

bsmTimeColumn = 'bsmTime'
psmTimeColumn = 'psmTime'

#Tuple Elements: (column Name, unit conversion, test to see if unavailable)
BSMInterpColumns_Units = [('coredatalat', 0.0000001, lambda t : t == 900000001),
                          ('coredatalong', 0.0000001, lambda t: t == 1800000000),
                          ('coredataelev', 0.1, lambda t: t==-4096),
                          ('coredataaccuracysemimajor', 0.05, lambda t: t==255),
                          ('coredataaccuracysemiminor', 0.05, lambda t: t==255),
                          ('coredataaccuracyorientation', float(360)/float(65535), lambda t: t==65535),
                          ('coredataspeed', 0.02, lambda t: t==8181),
                          ('coredataheading', 0.0125, lambda t: t==28800),
                          ('coredatabrakeswheelbrakes', 1, lambda t: t==10000),
                          ('coredataaccelsetlat', 0.01, lambda t: t==2001),
                          ('coredataaccelsetlong', 0.01, lambda t: t==2001),
                          ('coredataaccelsetvert', 0.1962, lambda t: t==-64),
                          ('coredataaccelsetyaw', 0.01, lambda t: False),
                          ('coredatasizewidth', 0.01, lambda t: t==0),
                          ('coredatasizelength', 0.01, lambda t: t==0)
                         ]

print('Interpolating data from {} alerts'.format(len(eventRecords)))
for index, event in eventRecords.iterrows():
    eventTime = event['metadataloggeneratedat']
    print('Event Time: {}. Organizing...'.format(eventTime))
    hostvehicleID = hex(int(event['hvbsmid'])).split('x')[1].upper()
    remotevehicleID = event['rvbsmid']
    
    lowerBSMLimit = eventTime - datetime.timedelta(seconds=60)
    upperBSMLimit = eventTime + datetime.timedelta(seconds=60)
    
    lowerString = lowerBSMLimit.strftime('%Y-%m-%d %H:%M:%S.%f')
    upperString = upperBSMLimit.strftime('%Y-%m-%d %H:%M:%S.%f')
    
    hostvehicleBSMQuery = 'select * from dbo.thea_sentbsm_core \
                           where metadatahostvehicleid = \'{0}\' \
                           and (bsmTime > \'{1}\' and bsmTime < \'{2}\')'.format(hostvehicleID, lowerString[0:-3], upperString[0:-3])
    
    remotevehicleBSMQuery = 'select * from dbo.thea_receivedbsm_core \
                             where metadatahostvehicleid = \'{0}\' \
                             and coredataid = \'{1}\' \
                             and (bsmTime > \'{2}\' and bsmTime < \'{3}\')'.format(hostvehicleID, remotevehicleID, lowerString[0:-3], upperString[0:-3])

    # PSMQuery = 'select * from dbo.thea_receivedbsm_core \
    #                         where metadatahostvehicleid = \'{0}\' \
    #                         and dataid = {1} \
    #                         and (metadataloggeneratedat > \'{2}\' and metadataloggeneratedat < \'{3}\')'.format(hostvehicleID, vrupsmid, lowerString[0:-3], upperString[0:-3])
    print('complete')
    print('Event Time: {}. Querying database...'.format(eventTime))
    hostVehicleBSMs = pandas.read_sql(hostvehicleBSMQuery, con=MSSQLEngine).drop_duplicates(subset=['metadataloggeneratedat','coredatasecmark','coredatalat','coredatalong','coredataid'])
    remoteVehicleBSMs = pandas.read_sql(remotevehicleBSMQuery, con=MSSQLEngine).drop_duplicates(subset=['metadataloggeneratedat','coredatasecmark','coredatalat','coredatalong', 'coredataid'])
    
    if len(hostVehicleBSMs) == 0 or len(remoteVehicleBSMs) == 0:
        print('There are no host or remote bsm records for this event, maybe try to interpolate later!')
        continue
    
    print('complete')
    print('sorting')
    hostVehicleBSMs.sort_values(by=['bsmTime'], inplace=True)
    remoteVehicleBSMs.sort_values(by=['bsmTime'], inplace=True)
    print('complete')
    
    
    interpedHost = pandas.DataFrame()
    interpedRemote = pandas.DataFrame()
    
    hostTimeBounds = [hostVehicleBSMs['bsmTime'].iloc[0], hostVehicleBSMs['bsmTime'].iloc[-1]]
    remoteTimeBounds = [remoteVehicleBSMs['bsmTime'].iloc[0], remoteVehicleBSMs['bsmTime'].iloc[-1]]
    
    hostDiffTimes = [(bsmTime - eventTime).total_seconds() for bsmTime in hostVehicleBSMs.loc[:,'bsmTime']]
    remoteDiffTimes = [(bsmTime - eventTime).total_seconds() for bsmTime in remoteVehicleBSMs.loc[:,'bsmTime']]
    
    hostDeciTimes = pandas.date_range(start = hostTimeBounds[0].ceil(freq='100ms'), end=hostTimeBounds[1].floor(freq='100ms'), freq='100ms')
    remoteDeciTimes =  pandas.date_range(start = remoteTimeBounds[0].ceil(freq='100ms'), end=remoteTimeBounds[1].floor(freq='100ms'), freq='100ms')
    
    hostDeciDiffTimes = [(bsmTime - eventTime).total_seconds() for bsmTime in hostDeciTimes]
    remoteDeciDiffTimes = [(bsmTime - eventTime).total_seconds() for bsmTime in remoteDeciTimes]
    
    interpedHost['datetimestamp'] = hostDeciTimes
    interpedRemote['datetimestamp'] = remoteDeciTimes
    
    print('starting interpolations...')
    for interpColumn in BSMInterpColumns_Units:
        if interpColumn[0] == 'coredatabrakeswheelbrakes':
            interpHost = interp.interp1d(hostDiffTimes, hostVehicleBSMs[interpColumn[0]], axis=0, kind='nearest', bounds_error = True)
            interpRemote = interp.interp1d(remoteDiffTimes, remoteVehicleBSMs[interpColumn[0]], axis=0, kind='nearest', bounds_error = True)
        else:
            interpHost = interp.interp1d(hostDiffTimes, hostVehicleBSMs[interpColumn[0]], axis=0, kind='linear', bounds_error = True)
            interpRemote = interp.interp1d(remoteDiffTimes, remoteVehicleBSMs[interpColumn[0]], axis=0, kind='linear', bounds_error = True)
         
        deciHostData = interpHost(hostDeciDiffTimes)
        deciRemoteData = interpRemote(remoteDeciDiffTimes)
         
        interpedHost[interpColumn[0]] = pandas.Series([int(point)*interpColumn[1] if not interpColumn[2](point) else None for point in deciHostData])
        interpedRemote[interpColumn[0]] = pandas.Series([int(point)*interpColumn[1] if not interpColumn[2](point) else None  for point in deciRemoteData])
         
    interpedHost.insert(0, 'eventID', pandas.Series([event['eventID'] for time in interpedHost['datetimestamp']]))
    interpedRemote.insert(0, 'eventID', pandas.Series([event['eventID'] for time in interpedRemote['datetimestamp']]))
    interpedHost.insert(0, 'hostVehicleID', pandas.Series([hostvehicleID for time in interpedHost['datetimestamp']]))
    interpedRemote.insert(0, 'remoteVehicleID', pandas.Series([remotevehicleID for time in interpedRemote['datetimestamp']]))
    interpedHost.insert(0, 'warningType', pandas.Series([event['metadataeventtype'] for time in interpedHost['datetimestamp']]))
    interpedRemote.insert(0, 'warningType', pandas.Series([event['metadataeventtype'] for time in interpedRemote['datetimestamp']]))
    
    print('complete')
    print('loading back into SQL Server')
    
    interpedHost.to_sql(name='Volpe_SentBSM_interpedEventData', con=MSSQLEngine, if_exists='append')
    interpedRemote.to_sql(name='Volpe_ReceivedBSM_interpedEventData', con=MSSQLEngine, if_exists='append')
    print('complete')

eventRecords.to_sql(name='Volpe_warningFCW_unique', con=MSSQLEngine, if_exists='append')   
 
#columnToPlot = 'coredataelev'
#plt.plot(hostVehicleBSMs['metadataloggeneratedat'], hostVehicleBSMs[columnToPlot], '.')
#plt.plot(interpedHost['datetimestamp'], interpedHost[columnToPlot], '.')
