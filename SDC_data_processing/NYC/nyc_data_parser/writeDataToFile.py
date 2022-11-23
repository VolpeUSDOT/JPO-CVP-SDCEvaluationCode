import json
import boto3
import os
import sys
import gzip
from uuid import uuid4
import uuid

DataLakeBucketName = os.environ.get('DATA_LAKE_BUCKET_NAME')


def uploadString(content, s3_key='cv/nyc/debug/1.txt'):
    s3_client = boto3.client('s3', region_name='us-east-1')
    s3_client.put_object(Bucket=DataLakeBucketName, Key=s3_key, Body=content, ServerSideEncryption='AES256')


def uploadFile(local_key, s3_key):
    s3_client = boto3.client('s3', region_name='us-east-1')
    with open(local_key, 'rb') as f:
        content = f.read()
        s3_client.put_object(Bucket=DataLakeBucketName, Key=s3_key, Body=content, ServerSideEncryption='AES256')


def uploadMessagesGzip(messages, s3_path, file_name):
    file_name_gz = f'{file_name}.gz'
    s3_key = s3_path + file_name_gz

    # Write content to a file
    with open('/tmp/' + file_name, 'a+') as f:
        for item in messages:
            f.write(json.dumps(item) + '\n')

    with open('/tmp/' + file_name, 'rb') as src, gzip.open('/tmp/' + file_name_gz, 'wb') as dst:
        dst.writelines(src)

    # Upload RFBSM content and remove the local file after
    uploadFile('/tmp/' + file_name_gz, s3_key)
    os.remove('/tmp/' + file_name)
    os.remove('/tmp/' + file_name_gz)


def toFiles(eventMsg, subdatasets, s3_key):
    # Determine appropriate key for event based on original event key
    event_type = 'event' + str(eventMsg['eventHeader']['eventType']).upper()
    event_key_path = s3_key.split('/')[0] + '/' + s3_key.split('/')[1] + '/' + event_type + '/' + s3_key.split('/')[
        3] + '/' + s3_key.split('/')[4] + '/' + s3_key.split('/')[5] + '/'
    event_key_name = event_type + '_' + s3_key.split('_')[2].split('.')[0] + '.json'

    event_s3_key = event_key_path + event_key_name

    # Write event content to a file
    with open('/tmp/' + event_key_name, 'a+') as f:
        f.write(json.dumps(eventMsg) + '\n')

    # Upload event content and remove the local file after
    uploadFile('/tmp/' + event_key_name, event_s3_key)
    os.remove('/tmp/' + event_key_name)

    for key in subdatasets:
        subdataset_key_path = s3_key.split('/')[0] + '/' + s3_key.split('/')[1] + '/' + key + '/' + s3_key.split('/')[
            3] + '/' + s3_key.split('/')[4] + '/' + s3_key.split('/')[5] + '/'
        subdataset_key_name = key + '_' + s3_key.split('_')[2].split('.')[0] + '.json'

        subdataset_s3_key = subdataset_key_path + subdataset_key_name

        # Write sub-dataset content to a file
        with open('/tmp/' + subdataset_key_name, 'a+') as f:
            for item in subdatasets[key]:
                f.write(json.dumps(item) + '\n')

        # Upload sub-dataset content and remove the local file after
        uploadFile('/tmp/' + subdataset_key_name, subdataset_s3_key)
        os.remove('/tmp/' + subdataset_key_name)


def toFilesEventsGzip(eventMsgs, subdatasets, s3_key):
    for event_type in eventMsgs.keys():
        # Determine appropriate key for event based on original event key
        # event_type = 'event' + str(eventMsg['eventHeader']['eventType']).upper()

        event_key_path = s3_key.split('/')[0] + '/' + s3_key.split('/')[1] + '/' + event_type + '/' + s3_key.split('/')[
            3] + '/' + s3_key.split('/')[4] + '/' + s3_key.split('/')[5] + '/'
        event_key_name = event_type + '_' + str(uuid.uuid4()) + '.json'

        uploadMessagesGzip(eventMsgs[event_type], event_key_path, event_key_name)

    for key in subdatasets:
        subdataset_key_path = s3_key.split('/')[0] + '/' + s3_key.split('/')[1] + '/' + key + '/' + s3_key.split('/')[
            3] + '/' + s3_key.split('/')[4] + '/' + s3_key.split('/')[5] + '/'
        subdataset_key_name = key + '_' + str(uuid.uuid4()) + '.json'

        uploadMessagesGzip(subdatasets[key], subdataset_key_path, subdataset_key_name)


def toFilesRf(eventMsg, s3_key, batch_id):
    rfbsm_key_path = s3_key.split('/')[0] + '/' + s3_key.split('/')[1] + '/RFBSM/' + s3_key.split('/')[3] + '/' + \
                     s3_key.split('/')[4] + '/' + s3_key.split('/')[5] + '/'
    rfbsm_key_name = 'RFBSM_' + s3_key.split('_')[1].split('.')[0] + '_' + batch_id + '.json'
    rfbsm_s3_key = rfbsm_key_path + rfbsm_key_name

    # Write RFBSM content to a file
    with open('/tmp/' + rfbsm_key_name, 'a+') as f:
        for item in eventMsg:
            f.write(json.dumps(item) + '\n')

    # Upload RFBSM content and remove the local file after
    uploadFile('/tmp/' + rfbsm_key_name, rfbsm_s3_key)
    os.remove('/tmp/' + rfbsm_key_name)


def toFilesRfGzip(eventMsg, s3_key, batch_id):
    rfbsm_key_path = s3_key.split('/')[0] + '/' + s3_key.split('/')[1] + '/RFBSM/' + s3_key.split('/')[3] + '/' + \
                     s3_key.split('/')[4] + '/' + s3_key.split('/')[5] + '/'
    rfbsm_key_name = 'RFBSM_' + batch_id + '.json'

    uploadMessagesGzip(eventMsg, rfbsm_key_path, rfbsm_key_name)
