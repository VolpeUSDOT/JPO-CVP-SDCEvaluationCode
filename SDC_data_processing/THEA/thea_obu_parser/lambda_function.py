from uuid import uuid4
import json
import xml.etree.ElementTree as ET
import datetime as dt
import copy
import csv
import os
import sys
import shutil
import gzip
import boto3
import uuid
import dateutil.parser
from xmljsonBC import parker
import botocore
from datetime import datetime
from collections import OrderedDict

Scratch_Bucket_Name = os.environ.get('SCRATCH_BUCKET_NAME')

paths = ['sentBSM', 'receivedBSM', 'receivedSPAT', 'receivedMAP', 'sentSRM', 'receivedSSM', 'receivedPSM', 'warningFCW',
         'warningWWE', 'warningVTRFTV', 'warningPCW', 'warningEEBL', 'warningIMA', 'warningERDW']
names = []

def convert_timestamp(year, timeStamp, secMark):
    timePastYear = dt.timedelta(minutes=timeStamp, milliseconds=secMark)
    yearDT = dt.datetime(year, 1, 1)
    date_time = yearDT + timePastYear
    return date_time.isoformat()

def build_eventReocrd(jsonData, UniversalInfo, LogEvent):
    metadata = {}
    payload = {}
    eventRecord = {}

    metadata = copy.deepcopy(UniversalInfo)
    metadata['logGeneratedAt'] = convert_timestamp(jsonData['year'], LogEvent['timeStamp'], LogEvent['secMark'])
    metadata['eventType'] = next(iter(LogEvent['eventType']))

    if "warning" in metadata['eventType']:
        payload = copy.deepcopy(LogEvent['eventData']['WarningEventData'])
    elif "sysMonMessage" in metadata['eventType'] or "sysMonHealth" in metadata['eventType']:
        payload = copy.deepcopy(LogEvent['eventData'])
    else:
        metadata['dot3'] = copy.deepcopy(LogEvent['eventData']['WSMP-EventData']['dot3'])
        payload = copy.deepcopy(LogEvent['eventData']['WSMP-EventData']['message'])

    eventRecord = {'metadata': copy.deepcopy(metadata), 'payload': copy.deepcopy(payload)}
    return copy.deepcopy(eventRecord)
    
def groom_record(json):
    if len(json) == 1:
        if next(iter(json.values())) == '':
            return next(iter(json))

    key_iter = iter(json)
    for value in json.values():
        key = next(key_iter)
        if type(value) is OrderedDict or type(value) is dict:
            json[key] = groom_record(value)
      
        elif type(value) is list:
            for i in range(0, len(value)):
                if type(value[i]) is dict:
                    newval = groom_record(value[i])
                    if type(newval) is OrderedDict or type(newval) is dict:
                        value[i] = newval

    return json

def parse_dataLogMessage(dataLog):
    jsonData = parker.data(ET.fromstring(dataLog['DataLogMessage']))

    # Create Unique data log ID
    logID = str(uuid4())

    UniversalInfo = {}
    UniversalInfo['logUploadedAt'] = convert_timestamp(jsonData['year'], jsonData['timeStamp'], jsonData['secMark'])
    UniversalInfo['msgCnt'] = jsonData['msgCnt']
    UniversalInfo['burstCnt'] = jsonData['burstCnt']
    UniversalInfo['burstID'] = jsonData['burstID']
    UniversalInfo['hostVehicleID'] = format(jsonData['deviceID'], 'X')[-6:]
    UniversalInfo['logPSID'] = dataLog['logPSID']
    UniversalInfo['rsuList'] = dataLog['rsuList']
    if ':' in str(dataLog['receivedRSUTimestamps']):
        UniversalInfo['receivedRSUTimestamps'] = int(dataLog['receivedRSUTimestamps'][:dataLog['receivedRSUTimestamps'].find(':')])
    else:
        UniversalInfo['receivedRSUTimestamps'] = dataLog['receivedRSUTimestamps']
    UniversalInfo['DataLogID'] = logID

    eventList = []

    for LogEvent in jsonData['logEvents']['DataLogEvent']:
        if type(LogEvent) is str:
            continue
        eventRecord = build_eventReocrd(jsonData, UniversalInfo, LogEvent)
        groom_record(eventRecord)
        eventList.append(copy.deepcopy(eventRecord))

    return copy.deepcopy(eventList)

def process_line(csvElements):
    LogInfo = {}
    LogInfo['logTimeStamp'] = csvElements[0]
    LogInfo['dataType'] = csvElements[1]
    LogInfo['logPSID'] = csvElements[2]
    LogInfo['DataLogMessage'] = csvElements[3].strip('"')
    LogInfo['rsuList'] = csvElements[4]
    LogInfo['receivedRSUTimestamps'] = csvElements[5]

    return copy.deepcopy(parse_dataLogMessage(LogInfo))

def Pre_Process_File(filePath, bucket_name, key, id_uuid):
    eventLists = {}

    lineNum = 0
    with open(filePath, "r") as file:
        csv_parsed = csv.reader(file, delimiter=',', quotechar='"')
        for line in csv_parsed:
            lineNum += 1
            try:
                allEvents = process_line(line)
                
                for eventRecord in allEvents:
                    if eventRecord['metadata']['eventType'] in eventLists.keys():
                        eventLists[eventRecord['metadata']['eventType']].append(copy.deepcopy(eventRecord))
                    else:
                        eventLists[eventRecord['metadata']['eventType']] = []
                        eventLists[eventRecord['metadata']['eventType']].append(copy.deepcopy(eventRecord))

                if lineNum % 100 == 0:
                    print("Prograss Update, " + str(lineNum) + " lines processed")
                    write_output(copy.deepcopy(eventLists), bucket_name, key, id_uuid)
                    eventLists = {}
            except Exception as e:
                continue
    
    write_output(copy.deepcopy(eventLists), bucket_name, key, id_uuid)

    # return eventLists

def write_output(output, bucket_name, key, id_uuid):
    # Extract name and file path out of the key
    s3_client = boto3.client('s3', region_name='us-east-1')
    key_name = key[(key.rfind('/') + 1):]
    key_path = key[:key.rfind('/')]
    key_path_1 = key_path[:(key_path.find('OBU') + 4)]
    key_path_2 = key_path[(key_path.find('OBU') + 3):]

    for path in paths:
        try:
            # Create name of file for scratch bucket with uuid
            key_name_1 = key_name[:key_name.find('.')]
            key_ext = key_name[key_name.find('.'):]
            name = key_path_1 + path + key_path_2 + '/' + (key_name_1 + '_' + id_uuid + '_' + path + key_ext).replace(
                '.csv.gz', '.json')

            if name in names:
                s3 = boto3.resource('s3', region_name='us-east-1')
                bucket = s3.Bucket(Scratch_Bucket_Name)
                local_file = '/tmp/localFile'
                bucket.download_file(name, local_file)
                appends = 0
                with open(local_file, 'a+') as f:
                    for message in output[path]:
                        if 'DECODEFAILED' not in str(message):
                            if 'warning' in path:
                                message = process_warning(message, path)
                            f.write(json.dumps(message) + '\n')
                            appends += 1
                        else:
                            print('Excluding DECODEFAILED message from ' + str(path))

                # Upload file to S3 bucket if there is new data added and remove it from local memory
                if appends > 0:
                    with open(local_file, 'rb') as f:
                        content = f.read()
                        s3_client.put_object(Bucket=Scratch_Bucket_Name, Key=name, Body=content, ServerSideEncryption='AES256')
                os.remove(local_file)
            else:
                appends = 0
                # Create local file for newly parsed JSON data
                with open('/tmp/' + key_name, 'a+') as f:
                    for message in output[path]:
                        if 'DECODEFAILED' not in str(message):
                            if 'warning' in path:
                                message = process_warning(message, path)
                            f.write(json.dumps(message) + '\n')
                            appends += 1
                        else:
                            print('Excluding DECODEFAILED message from ' + str(path))

                # Upload file to S3 bucket if there is actual data and remove it from local memory
                if appends > 0:
                    names.append(name)
                    with open('/tmp/' + key_name, 'rb') as f:
                        content = f.read()
                        s3_client.put_object(Bucket=Scratch_Bucket_Name, Key=name, Body=content, ServerSideEncryption='AES256')
                os.remove('/tmp/' + key_name)
        except Exception as e:
            if str(e) == "'" + str(path) + "'":
                pass
            else:
                raise e

def process_warning(message, path):    
    if path == 'warningWWE' or path == 'warningERDW':
        logTypes = ['hvBSM']
    elif path == 'warningPCW':
        logTypes = ['hvBSM', 'vruPSM']
    else:
        logTypes = ['hvBSM', 'rvBSM']
    for logType in logTypes:
        if 'DECODEFAILED' not in message['payload'][logType]:
            message['metadata'][logType] = {}
            dateTime = message['metadata']['logGeneratedAt']
            if 'BSM' in logType:
                message['metadata'][logType]['id'] = json.dumps(message['payload'][logType]['MessageFrame']['value']['BasicSafetyMessage']['coreData']['id'])
                message['metadata'][logType]['lat'] = json.dumps(message['payload'][logType]['MessageFrame']['value']['BasicSafetyMessage']['coreData']['lat'])
                message['metadata'][logType]['long'] = json.dumps(message['payload'][logType]['MessageFrame']['value']['BasicSafetyMessage']['coreData']['long'])

                secMark = json.dumps(message['payload'][logType]['MessageFrame']['value']['BasicSafetyMessage']['coreData']['secMark']).zfill(5) + '000'
                # create datetime from secMark for the BSM
                message['metadata'][logType]['DateTime'] = dateutil.parser.parse(dateTime).replace(second=int(secMark[:2]), microsecond=int(secMark[2:])).strftime('%Y-%m-%dT%H:%M:%S.%f')

            elif 'PSM' in logType:
                message['metadata'][logType]['id'] = json.dumps(message['payload'][logType]['MessageFrame']['value']['PersonalSafetyMessage']['id'])
                message['metadata'][logType]['lat'] = json.dumps(message['payload'][logType]['MessageFrame']['value']['PersonalSafetyMessage']['position']['lat'])
                message['metadata'][logType]['long'] = json.dumps(message['payload'][logType]['MessageFrame']['value']['PersonalSafetyMessage']['position']['long'])

                secMark = json.dumps(message['payload'][logType]['MessageFrame']['value']['PersonalSafetyMessage']['secMark']).zfill(5) + '000'
                # create datetime from secMark for the BSM
                message['metadata'][logType]['DateTime'] = dateutil.parser.parse(dateTime).replace(second=int(secMark[:2]), microsecond=int(secMark[2:])).strftime('%Y-%m-%dT%H:%M:%S.%f')
        else:
            return 'DECODEFAILED'

    message['metadata']['driverWarn'] = message['payload']['driverWarn']
    message['metadata']['isControl'] = message['payload']['isControl']
    message['metadata']['isDisabled'] = message['payload']['isDisabled']

    if path == 'warningERDW':
        message['metadata']['erdwSpeed'] = message['payload']['erdwSpeed']

    print('----------------------')
    print('warning message parsed')
    print('----------------------')

    payload_string = ''
    if len(logTypes) is 1:
        payload_string = '{\"' + logTypes[0] + '\": ' + str(json.dumps(message['payload'][logTypes[0]])) + '}'
    else:
        payload_string = '{\"' + logTypes[0] + '\": ' + str(json.dumps(message['payload'][logTypes[0]])) + ', {\"' + logTypes[1] + '\": ' + str(json.dumps(message['payload'][logTypes[1]]) + '}')
    message['payload'] = payload_string
    return message

def lambda_handler(event, context):
    sns_message = json.loads(event["Records"][0]["Sns"]["Message"])
    bucket_name = sns_message["Bucket"]
    key = sns_message["Key"]

    print(bucket_name, key)
    if key[-1] == '/':
        print('This is a new directory, not a file. Terminating process')
        return

    s3 = boto3.resource('s3', region_name='us-east-1')
    bucket = s3.Bucket(bucket_name)
    local_key = '/tmp/thea_obu.csv'
    unzipped_local_key = '/tmp/unzip-thea_obu.csv'
    bucket.download_file(key, local_key)
    with gzip.open(local_key, 'rb') as f_in:
        with open(unzipped_local_key, 'wb+') as f_out:
            shutil.copyfileobj(f_in, f_out)
    os.remove(local_key)
    # s3_client.upload_file(unzipped_local_key, bucket_name, 'cv/thea/obulog/unzip.csv')
    id_uuid = str(uuid.uuid4())
    Pre_Process_File(unzipped_local_key, bucket_name, key, id_uuid)
    os.remove(unzipped_local_key)
    s3Client = boto3.client('s3', region_name='us-east-1')

    for name in names:
        copy_source = {
            'Bucket': Scratch_Bucket_Name,
            'Key': name
        }
        print(copy_source)
        s3.meta.client.copy_object(CopySource=copy_source, Bucket=bucket_name, Key=name, ServerSideEncryption='AES256')
        s3Client.delete_object(Bucket=Scratch_Bucket_Name, Key=name)
    names.clear()
