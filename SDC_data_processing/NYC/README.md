# NYCDOT Data Processing Examples

## NYCDOT On-Board Unit (OBU) log processor
### Purpose
The nyc_data_parser folder contains Python code for an AWS Lambda function, which is responsible for taking a raw OBU log file location as an input, determining if a file contains ASDRF or EVENT type of messages, and if does - do the processing of these files and separate them into fursther submessage types, and if not - write it to the output location unchanged.

### Inputs

lambda_handler function inside of lambda_function.py source file is the entry point into the application.

The lambda function would receive S3 bucket name and a file name ("Key") for the location of a raw log file as part of the function invocation context argument. File name would contain a message type in its name.

### Outputs

As a result of execution, for ASDRF and EVENT files - specific message type data files are created and written into dedicated subfolders in the same S3 bucket where the raw log file resides; for other message types the file would be saved unchanged.

### High level execution flow

1. Determine the message type contained in a file based on a file name
2. For ASDRF messages:
- Download the file (in gzip format) to a temporary local folder
- Unzip it
- Parse the file for each message and separate messages into specific message type files
3. For EVENT messages:
- Download the file (in gzip format) to a temporary local folder
- Unzip it
- Parse the file for each message and separate messages into specific message type files
4. For all other message type files: write it as-is to a destination



