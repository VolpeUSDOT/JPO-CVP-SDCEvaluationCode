import json
import boto3
import os
import sys
import shutil
import gzip
import time
from uuid import uuid4
import uuid
import fileinput
import pprint;
import traceback
import writeDataToFile as writeData

subdatasetlist = {'bsmList': 'BSM', 'mapList': 'MAP', 'spatList': 'SPAT', 'timList': 'TIM'}


def curateSubDataset(dataset, dataList, eventid, eventType, hostVehId, targetVehId):
    # print('Sub-Dataset: ' + dataset)

    curatedDataList = []

    for item in dataList:
        # If a BSM message, insert a field that states whether it is a host, target or undefined vehicle
        if dataset == 'bsmList':
            if item['bsmRecord']['bsmMsg']['coreData']['id'] == hostVehId:
                item['vehicleRole'] = 'host'
            elif item['bsmRecord']['bsmMsg']['coreData']['id'] == targetVehId:
                item['vehicleRole'] = 'target'
            else:
                item['vehicleRole'] = 'undefined'

        item['eventid'] = eventid
        item['eventType'] = eventType

        curatedDataList.append(item)

    return curatedDataList


def parseEvent(filePath):
    # print(f'File path: {filePath}')

    with open(filePath, "r") as file:
        message = file.read().decode('utf-8')

    return parseEventText(message)


def parseEventText(message):
    curatedEventRecord = {}
    curatedSubDatasets = {}
    eventid = str(uuid.uuid4())

    eventData = json.loads(message)

    # Grab event type and host, remote vehicle id for BSMs
    eventType = eventData['eventHeader']['eventType']
    hostVehId = eventData['eventHeader']['hostVehID']
    targetVehId = eventData['eventHeader']['targetVehID']

    # print('Event Type: ' + str(eventType))
    # print('Host Vehicle ID: ' + str(hostVehId))
    # print('Target Vehicle ID: ' + str(targetVehId))

    # Save curated event data to the dictionary
    curatedEventRecord['eventHeader'] = eventData['eventHeader']
    curatedEventRecord['eventHeader']['parameters']['timeRecordBefore'] = int(
        curatedEventRecord['eventHeader']['parameters']['timeRecordBefore'])
    curatedEventRecord['eventHeader']['parameters']['timeRecordFollow'] = int(
        curatedEventRecord['eventHeader']['parameters']['timeRecordFollow'])
    curatedEventRecord['eventid'] = eventid

    for key in eventData:
        # Ignore eventHeader
        if key == 'eventHeader':
            continue

        # Edit each list element based on the type of sub-dataset it is
        subDataset = curateSubDataset(key, eventData[key], eventid, eventType, hostVehId, targetVehId)

        # Assign to curated sub-dataset list
        curatedSubDatasets[subdatasetlist[key]] = subDataset

    return curatedEventRecord, curatedSubDatasets


def parseBSM(content, timedata, role, rfid):
    rfbsm = {}

    rfbsm['rfid'] = rfid
    rfbsm['role'] = role
    rfbsm['bsmTime'] = timedata
    rfbsm['bsm'] = content

    return rfbsm


def parseRf(filePath):
    print(f'Starting RFBSM parsing: {filePath}')

    rfbsmlist = []

    with open(filePath, "r") as file:
        eventData = json.load(file)

        bsmlist = eventData['bsmRFList']

        print('Number of items in list: ' + str(len(bsmlist)))

        for rfbsm in bsmlist:
            rfid = str(uuid.uuid4())
            rfbsmlist.append(parseBSM(rfbsm['firstHVBSM'], rfbsm['firstBSMTime'], 'firstHVBSM', rfid))
            rfbsmlist.append(parseBSM(rfbsm['firstRVBSM'], rfbsm['firstBSMTime'], 'firstRVBSM', rfid))
            rfbsmlist.append(parseBSM(rfbsm['lastHVBSM'], rfbsm['lastBSMTime'], 'lastHVBSM', rfid))
            rfbsmlist.append(parseBSM(rfbsm['lastRVBSM'], rfbsm['lastBSMTime'], 'lastRVBSM', rfid))

    return rfbsmlist


# for a consolidated file, this method will execute millions of times.
# do not have any printouts in here for the prod version - to keep the logs clean!!!
def parseRfMessage(eventData):
    # print(f'Starting RFBSM message packaging')

    rfbsmlist = []

    bsmlist = eventData['bsmRFList']

    # print('Number of items in list: ' + str(len(bsmlist)))

    for rfbsm in bsmlist:
        rfid = str(uuid.uuid4())
        rfbsmlist.append(parseBSM(rfbsm['firstHVBSM'], rfbsm['firstBSMTime'], 'firstHVBSM', rfid))
        rfbsmlist.append(parseBSM(rfbsm['firstRVBSM'], rfbsm['firstBSMTime'], 'firstRVBSM', rfid))
        rfbsmlist.append(parseBSM(rfbsm['lastHVBSM'], rfbsm['lastBSMTime'], 'lastHVBSM', rfid))
        rfbsmlist.append(parseBSM(rfbsm['lastRVBSM'], rfbsm['lastBSMTime'], 'lastRVBSM', rfid))

    return rfbsmlist


def extract_message_and_datasets(s, eventRecords, subDataSets):
    s = s.replace('\r', '').replace('\n', '') + '\n'

    curatedEventRecord, curatedSubDatasets = parseEventText(s)
    event_type = 'event' + str(curatedEventRecord['eventHeader']['eventType']).upper()
    if event_type not in eventRecords.keys():
        eventRecords[event_type] = []

    eventRecords[event_type].append(curatedEventRecord)
    for dataset_key in curatedSubDatasets:
        if dataset_key not in subDataSets.keys():
            subDataSets[dataset_key] = []

        subDataSets[dataset_key].extend(curatedSubDatasets[dataset_key])

    return eventRecords, subDataSets


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

    # If rf parse rf file, otherwise parse the event message into parts
    if key.split('/')[2] == 'ASDRF':
        # Download NYC file from Data Lake and unzip it
        local_key = '/tmp/nyc_rfbsm'
        unzipped_local_key = '/tmp/unzip-nyc_rfbsm'
        bucket.download_file(key, local_key)

        with gzip.open(local_key, 'rb') as f:
            content = f.read()
        s = '{"messages": [' + str(content, 'utf-8') + ']}'
        s = s.replace('\r\n', '')
        s = s.replace('}\n{', '},\n{')
        s = s.replace('\n', '')

        messages = json.loads(s)['messages']

        events = []

        cnt = 0
        for m in messages:
            # print(m)
            f_batch_id = str(uuid.uuid4())
            eventMsg = parseRfMessage(m)
            events.extend(eventMsg)
            # print(f'Messages in a batch: {len(eventMsg)}')

            cnt += 1
            if cnt > 1000:
                # Write data to file and upload files to Data Lake (GZip Files)
                writeData.toFilesRfGzip(events, key, f_batch_id)
                cnt = 0
                events = []

        # final dump
        if len(events) > 0:
            # Write data to file and upload files to Data Lake (GZip Files)
            writeData.toFilesRfGzip(events, key, f_batch_id)

    else:

        if key.split('/')[2] == 'EVENT':

            try:

                # Download NYC file from Data Lake and unzip it
                local_key = '/tmp/nyc_event'
                unzipped_local_key = '/tmp/unzip-nyc_event'
                bucket.download_file(key, local_key)
                ##with gzip.open(local_key, 'rb') as f_in:
                ##    with open(unzipped_local_key, 'wb+') as f_out:
                ##        shutil.copyfileobj(f_in, f_out)

                # ss = ''
                eventRecords = {}
                subDataSets = {}
                s = ''
                cnt = 0
                with gzip.open(local_key, 'rb') as f_in:
                    while True:
                        line = f_in.readline().decode('utf-8')
                        if not line:
                            break

                        if line == '}{\r\n':
                            s += '}'

                            eventRecords, subDataSets = extract_message_and_datasets(s, eventRecords, subDataSets)

                            s = '{'

                            cnt += 1
                            if cnt > 100:
                                writeData.toFilesEventsGzip(eventRecords, subDataSets, key)
                                cnt = 0
                                eventRecords = {}
                                subDataSets = {}

                        else:
                            s += line

                eventRecords, subDataSets = extract_message_and_datasets(s, eventRecords, subDataSets)

                # Write data to file and upload files to Data Lake
                writeData.toFilesEventsGzip(eventRecords, subDataSets, key)

            except Exception as e:
                print(str(e))
                traceback.print_exc()

                # Download and parse the data to subdatasets
                bucket.download_file(key, local_key)

                eventMsg, subdatasets = parseEvent(local_key)

                # Write data to file and upload files to Data Lake
                writeData.toFiles(eventMsg, subdatasets, key)

    print('Parse Completed')

