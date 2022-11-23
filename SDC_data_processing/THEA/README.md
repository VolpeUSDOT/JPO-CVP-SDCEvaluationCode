# THEA Data Processing Examples

## THEA On-Board Unit (OBU) log processor
### Purpose
The thea_obu_parser folder contains Python code for an AWS Lambda function, which was responsible for taking a raw OBU log file location as an input, extract specific message type logs, and then write these specific message type logs into dedicated output files.

### Inputs

lambda_handler function inside of lambda_function.py source file is the entry point into the application.

The lambda function would receive S3 bucket name and a file name ("Key") for the location of a raw log file as part of the function invocation context argument.

### Outputs

As a result of execution, specific message type data files are created and written into dedicated subfolders in the same S3 bucket where the raw log file resides.

Message types supported:
- sentBSM
- receivedBSM
- receivedSPAT
- receivedMAP
- sentSRM
- receivedSSM
- receivedPSM
- warningFCW
- warningWWE
- warningVTRFTV
- warningPCW
- warningEEBL
- warningIMA
- warningERDW

### High level execution flow

1. Download the raw log file (in gzip format) to a temporary local folder
2. Unzip the raw log file
3. Parse the raw log file for each message and separate messages into specific message type files
4. Write specific message type files to their designated locations

Pre_Process_File function is the one that encapsulates the actual parser by message type.  

