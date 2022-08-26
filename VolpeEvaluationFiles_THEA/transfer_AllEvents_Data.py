import sqlalchemy
import pandas as pd
import time
import datetime
import PySDC

from progressBar import update_progress

import credentials

def getCorrectMessageTime(logSeconds, logMinutes, bsmSeconds):
    if logSeconds > pd.Timedelta(seconds = 30):
        return (logMinutes + pd.Timedelta(minutes=1)) + bsmSeconds
    else:
        return (logMinutes - pd.Timedelta(minutes=1)) + bsmSeconds

def getCorrectMessageDate(loggedAt, loggedMins):
    print('Correcting a Date\n\n')
    return pd.datetime(year=(loggedAt.year - 1), month=1, day=1, hour=0, minute=0, second=0) + loggedMins
#    if loggedMins > pd.Timedelta(minutes = 262800):
#        return pd.datetime(year=(loggedAt.year - 1), month=1, day=1, hour=0, minute=0, second=0) + loggedMins
#    else:
#        return pd.datetime(year=(loggedAt.year + 1), month=1, day=1, hour=0, minute=0, second=0) + loggedMins

HiveConn = PySDC.connect_hive(host='172.18.1.20',
                            port=10000,
                            username=credentials.username,
                            password=credentials.password,
                            configuration={'hive.resultset.use.unique.column.names':'false'})

del credentials

replace = False

MSSQLEngine = sqlalchemy.create_engine('mssql+pyodbc://' #Driver
                                       'hadoop:hadoop@' #Username:Password
                                       '172.18.33.43' #Server IP
                                       '/THEADB_V2' #dbname
                                       '?driver=ODBC+Driver+17+for+SQL+Server')

datequery = ""#Where metadataloggeneratedat > '2019-03-01 00:00:00.000' and metadataloggeneratedat < '2020-02-01 00:00:00.000'"
replace = True

UpdateTablesList = [
                    'thea_allWarning_core'
                    'thea_receivedbsm_core',
                    'thea_receivedmap_core',
                    'thea_receivedpsm_core',
                    'thea_receivedspat_core',
                    'thea_sentbsm_core',
                    'thea_sentsrm_core',
                    'thea_warningfcw_core',
                    'thea_warningeebl_core',
                    'thea_warningima_core',
                    'thea_warningpcw_core',
                    'thea_warningvtrftv_core',
                    'thea_warningwwe_core'
                   ]

for tableName in UpdateTablesList:
    selectString = 'Select * From volpeie.{} {} order by starttime'.format(tableName, datequery)
    countString = 'Select count(*) From volpeie.{} {}'.format(tableName, datequery)
    
    countresult = pd.read_sql(sql=countString, con=HiveConn)['_c0'][0]
    
    chunkSize = 1000
    i=0
    print('Updating Table: {}, {} rows to insert'.format(tableName, countresult))
    lastTime = time.time()
    for chunk in pd.read_sql(sql=selectString,
                             con=HiveConn, 
                             chunksize=chunkSize):
        
        # Correct loggeneratedat if it has year rollover issue
        
        datesDF = pd.DataFrame()
        datesDF['uploadAt'] = chunk['uploadedtime']
        datesDF['uploadMins'] = pd.Series([uploadedAt - pd.datetime(year=uploadedAt.year, month=1, day=1, hour=0, minute=0, second=0) \
                                           for uploadedAt in chunk['starttime']])
        datesDF['loggedAt'] = chunk['starttime']
        datesDF['loggedMins'] = pd.Series([uploadedAt - pd.datetime(year=uploadedAt.year, month=1, day=1, hour=0, minute=0, second=0) \
                                           for uploadedAt in chunk['starttime']])
        datesDF['correctLogTimes'] = pd.Series([ getCorrectMessageDate(loggedAt, loggedMins) \
                                                 if  loggedAt > uploadAt and loggedAt - uploadAt > pd.Timedelta(minutes=1440) \
                                                 else loggedAt \
                                                 for uploadAt, loggedAt, uploadMins, loggedMins \
                                                 in zip(datesDF['uploadAt'], datesDF['loggedAt'], datesDF['uploadMins'], datesDF['loggedMins']) \
                                              ])
        
        chunk['starttime'] = datesDF['correctLogTimes']
        
       #Add corrected BSM date
       if tableName == 'thea_receivedbsm_core':
           chunk.dropna(axis=0, subset=['coredatasecmark'], inplace=True)

           secmarkSecs = pd.Series([pd.Timedelta(seconds=float(secmark)/float(1000)) for secmark in chunk['coredatasecmark']])

           datetimeseconds = pd.DataFrame()
           datetimeseconds['eventLogTime'] = chunk['metadataloggeneratedat']
           datetimeseconds['eventLogSecs'] = chunk['metadataloggeneratedat'] - chunk['metadataloggeneratedat'].dt.floor('Min')
           datetimeseconds['bsmSecMark'] = chunk['coredatasecmark']
           datetimeseconds['bsmSecs' ] = pd.Series([ \
                          getCorrectMessageTime(logSecs, logMins, bsmSecs) \
                          if logMins - uploadMins > pd.Timedelta(minutes=30) \
                          else logMins + bsmSecs \
                          for bsmSecs, logSecs, logMins, uploadMins \
                          in zip(secmarkSecs, datetimeseconds['eventLogSecs'], chunk['metadataloggeneratedat'].dt.floor('Min'), chunk['metadataloguploadedat'].dt.floor('Min')) \
                          ])
           chunk.insert(20, 'bsmTime', datetimeseconds['bsmSecs'])
             
       if tableName == 'thea_sentbsm_core':
           chunk.dropna(axis=0, subset=['coredatasecmark'], inplace=True)
           
           secmarkSecs = pd.Series([pd.Timedelta(seconds=float(secmark)/float(1000)) for secmark in chunk['coredatasecmark']])

           datetimeseconds = pd.DataFrame()
           datetimeseconds['eventLogTime'] = chunk['metadataloggeneratedat']
           datetimeseconds['eventLogSecs'] = chunk['metadataloggeneratedat'] - chunk['metadataloggeneratedat'].dt.floor('Min')
           datetimeseconds['bsmSecMark'] = chunk['coredatasecmark']
           datetimeseconds['bsmSecs' ] = pd.Series([ \
                          getCorrectMessageTime(logSecs, logMins, bsmSecs) \
                          if abs(logSecs - bsmSecs) > datetime.timedelta(seconds=30) \
                          else logMins + bsmSecs \
                          for bsmSecs, logSecs, logMins \
                          in zip(secmarkSecs, datetimeseconds['eventLogSecs'], chunk['metadataloggeneratedat'].dt.floor('Min')) \
                          ])
           chunk.insert(20, 'bsmTime', datetimeseconds['bsmSecs'])
           
       if tableName == 'thea_receivedpsm_core':
           chunk.dropna(axis=0, subset=['datasecmark'], inplace=True)
       
           secmarkSecs = pd.Series([pd.Timedelta(seconds=float(secmark)/float(1000)) for secmark in chunk['datasecmark']])

           datetimeseconds = pd.DataFrame()
           datetimeseconds['eventLogTime'] = chunk['metadataloggeneratedat']
           datetimeseconds['eventLogSecs'] = chunk['metadataloggeneratedat'] - chunk['metadataloggeneratedat'].dt.floor('Min')
           datetimeseconds['psmSecMark'] = chunk['datasecmark']
           datetimeseconds['psmSecs' ] = pd.Series([ \
                          getCorrectMessageTime(logSecs, logMins, bsmSecs) \
                          if abs(logSecs - bsmSecs) > datetime.timedelta(seconds=30) \
                          else logMins + bsmSecs \
                          for bsmSecs, logSecs, logMins \
                          in zip(secmarkSecs, datetimeseconds['eventLogSecs'], chunk['metadataloggeneratedat'].dt.floor('Min')) \
                          ])
           chunk.insert(20, 'psmTime', datetimeseconds['psmSecs'])
        print(chunk)
        if replace and i==0:
            i+=1
            print('Updated First')
            chunk.to_sql(tableName, 
                 con=MSSQLEngine, if_exists='replace' )
            continue
        i+=1
        chunk.to_sql(tableName, 
                 con=MSSQLEngine, if_exists='append')
        dur = time.time()-lastTime
        lastTime = time.time()
        rate = chunkSize/dur
        update_progress(i*chunkSize/countresult, rate)
    
    del selectString, countString, i

print("Done Updating all Tables!")