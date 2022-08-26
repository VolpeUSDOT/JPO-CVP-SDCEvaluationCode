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
                                       '/theadb' #dbname
                                       '?driver=ODBC+Driver+17+for+SQL+Server&'
                                       'trusted_connection=yes') #driver name

###############################################
###############################################
# Use This to decide which warning type and which warning(s) to choose

eventTableName = 'thea_warningpcw_core'
eventTimestampString = "metadataloggeneratedat > '2019-03-01 00:00:00' and metadataloggeneratedat < '2020-03-15 00:00:00'"

eventQueryString = 'select * from dbo.{0} \
                    where {1}'.format(eventTableName, eventTimestampString)

idColumnName = 'eeblid'

###############################################
###############################################

eventRecords = pandas.read_sql(eventQueryString, con=MSSQLEngine)
eventRecords.drop_duplicates(subset=['metadataloggeneratedat', 'hvbsmid', 'vrupsmid', 'hvbsmlat', 'hvbsmlong', 'vrupsmlat', 'vrupsmlong'], inplace=True)
eventRecords.sort_values(by=['metadataloggeneratedat'], inplace=True)
eventRecords.reset_index(inplace=True)
eventRecords.insert(0, 'eventID', eventRecords.index+1)
eventRecords.drop(columns=['pcwid', 'level_0', 'index'], inplace=True)
eventRecords['vrupsmid'] = eventRecords['vrupsmid'].str.replace('"', '')

bsmTimeColumn = 'bsmTime'
psmTimeColumn = 'psmTime'
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

PSMInterpColumns_Units = [('datapositionlat', 0.0000001, lambda t : t == 900000001),
                          ('datapositionlong', 0.0000001, lambda t: t == 1800000000),
                          ('dataaccuracysemimajor', 0.05, lambda t: t==255),
                          ('dataaccuracysemiminor', 0.05, lambda t: t==255),
                          ('dataaccuracyorientation', float(360)/float(65535), lambda t: t==65535),
                          ('dataspeed', 0.02, lambda t: t==8181),
                          ('dataheading', 0.0125, lambda t: t==28800),
                          ('datapathpredictionradiusofcurve', 0.01, lambda t: False),
                          ('datapathpredictionconfidence', 0.5, lambda t: False)
                         ]

print('Interpolating data from {} alerts'.format(len(eventRecords)))
for index, event in eventRecords.iterrows():
    eventTime = event['metadataloggeneratedat']
    print('Event Time: {}. Organizing...'.format(eventTime))
    hostvehicleID = hex(int(event['hvbsmid'])).split('x')[1].upper()
    psmID = event['vrupsmid']
    
    lowerBSMLimit = eventTime - datetime.timedelta(seconds=60)
    upperBSMLimit = eventTime + datetime.timedelta(seconds=60)
    
    lowerString = lowerBSMLimit.strftime('%Y-%m-%d %H:%M:%S.%f')
    upperString = upperBSMLimit.strftime('%Y-%m-%d %H:%M:%S.%f')
    
    hostvehicleBSMQuery = 'select * from dbo.thea_sentbsm_core \
                           where metadatahostvehicleid = \'{0}\' \
                           and (bsmTime > \'{1}\' and bsmTime < \'{2}\')'.format(hostvehicleID, lowerString[0:-3], upperString[0:-3])
    
    remotePSMQuery = 'select * from dbo.thea_receivedpsm_core \
                             where metadatahostvehicleid = \'{0}\' \
                             and dataid = \'{1}\' \
                             and (psmTime > \'{2}\' and psmTime < \'{3}\')'.format(hostvehicleID, psmID, lowerString[0:-3], upperString[0:-3])

    print('complete')
    print('Event Time: {}. Querying database...'.format(eventTime))
    hostVehicleBSMs = pandas.read_sql(hostvehicleBSMQuery, con=MSSQLEngine)
    hostVehicleBSMs.drop_duplicates(subset=['metadataloggeneratedat','coredatasecmark','coredatalat','coredatalong','coredataid'], inplace=True)
    remotePSMs = pandas.read_sql(remotePSMQuery, con=MSSQLEngine)
    remotePSMs.drop_duplicates(subset=['metadataloggeneratedat','datasecmark','datapositionlat','datapositionlong', 'dataid'], inplace=True)
    
    if len(hostVehicleBSMs) == 0 or len(remotePSMs) == 0:
        print('There are no host or remote bsm records for this event, maybe try to interpolate later!')
        continue
    
    print('complete')
    print('sorting')
    hostVehicleBSMs.sort_values(by=['bsmTime'], inplace=True)
    remotePSMs.sort_values(by=['psmTime'], inplace=True)
    print('complete')
    
    
    interpedHost = pandas.DataFrame()
    interpedPSMs = pandas.DataFrame()
    
    hostTimeBounds = [hostVehicleBSMs['bsmTime'].iloc[0], hostVehicleBSMs['bsmTime'].iloc[-1]]
    remoteTimeBounds = [remotePSMs['psmTime'].iloc[0], remotePSMs['psmTime'].iloc[-1]]
    
    hostDiffTimes = [(bsmTime - eventTime).total_seconds() for bsmTime in hostVehicleBSMs.loc[:,'bsmTime']]
    remoteDiffTimes = [(bsmTime - eventTime).total_seconds() for bsmTime in remotePSMs.loc[:,'psmTime']]
    
    hostDeciTimes = pandas.date_range(start = hostTimeBounds[0].ceil(freq='100ms'), end=hostTimeBounds[1].floor(freq='100ms'), freq='100ms')
    remoteDeciTimes =  pandas.date_range(start = remoteTimeBounds[0].ceil(freq='100ms'), end=remoteTimeBounds[1].floor(freq='100ms'), freq='100ms')
    
    hostDeciDiffTimes = [(bsmTime - eventTime).total_seconds() for bsmTime in hostDeciTimes]
    remoteDeciDiffTimes = [(psmTime - eventTime).total_seconds() for psmTime in remoteDeciTimes]
    
    interpedHost['datetimestamp'] = hostDeciTimes
    interpedPSMs['datetimestamp'] = remoteDeciTimes
    
    print('starting interpolations...')
    for interpColumn in BSMInterpColumns_Units:
        if interpColumn[0] == 'coredatabrakeswheelbrakes':
            interpHost = interp.interp1d(hostDiffTimes, hostVehicleBSMs[interpColumn[0]], axis=0, kind='nearest', bounds_error = True)
        else:
            interpHost = interp.interp1d(hostDiffTimes, hostVehicleBSMs[interpColumn[0]], axis=0, kind='linear', bounds_error = True)
         
        deciHostData = interpHost(hostDeciDiffTimes)
         
        interpedHost[interpColumn[0]] = pandas.Series([int(point)*interpColumn[1] if not interpColumn[2](point) else None for point in deciHostData])
    
    for interpColumn in PSMInterpColumns_Units:
        interpRemote = interp.interp1d(remoteDiffTimes, remotePSMs[interpColumn[0]], axis=0, kind='linear', bounds_error = True)
         
        deciRemoteData = interpRemote(remoteDeciDiffTimes)
         
        interpedPSMs[interpColumn[0]] = pandas.Series([int(point)*interpColumn[1] if not interpColumn[2](point) else None  for point in deciRemoteData])
        
    interpedHost.insert(0, 'eventID', pandas.Series([event['eventID'] for time in interpedHost['datetimestamp']]))
    interpedPSMs.insert(0, 'eventID', pandas.Series([event['eventID'] for time in interpedPSMs['datetimestamp']]))
    interpedHost.insert(0, 'hostVehicleID', pandas.Series([hostvehicleID for time in interpedHost['datetimestamp']]))
    interpedPSMs.insert(0, 'vrupsmid', pandas.Series([psmID for time in interpedPSMs['datetimestamp']]))
    interpedHost.insert(0, 'warningType', pandas.Series([event['metadataeventtype'] for time in interpedHost['datetimestamp']]))
    interpedPSMs.insert(0, 'warningType', pandas.Series([event['metadataeventtype'] for time in interpedPSMs['datetimestamp']]))
    
    print('complete')
    print('loading back into SQL Server')
    
    #interpedHost.to_sql(name='Volpe_SentBSM_interpedEventData', con=MSSQLEngine, if_exists='append')
    interpedPSMs.to_sql(name='Volpe_ReceivedPSM_interpedEventData', con=MSSQLEngine, if_exists='append')
    print('complete')

#eventRecords.to_sql(name='Volpe_warningPCW_unique', con=MSSQLEngine, if_exists='append')    

#columnToPlot = 'coredatalat'
##plt.plot(hostVehicleBSMs['metadataloggeneratedat'], hostVehicleBSMs[columnToPlot], '.')
#plt.plot(interpedHost['coredatalong'], interpedHost[columnToPlot], '.')
#
#columnToPlot = 'datapositionlat'
##plt.plot(hostVehicleBSMs['metadataloggeneratedat'], hostVehicleBSMs[columnToPlot], '.')
#plt.plot(interpedPSMs['datapositionlong'], interpedPSMs[columnToPlot], '.')
