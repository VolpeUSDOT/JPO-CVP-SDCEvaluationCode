# Volpe Data Processing and Evaluation Code

This "README" file describes the scripts used to process and analyze the THEA connected vehicle data sent to the SDC between 2019-06-01 to 2020-07-01.

## 1. TransferEventData.py
This script transfers data from the SDC's data warehouse. This script reads data from the tables in the list of table names where THEA's warning data is stored. Due to the way date's are encoded in the original data streams, some dates stored in the SDC's data warehouse are eroneous. Therefore, this transfer script attempts to recognize these erroneous dates and times and correct them, improving the quality of the resultant data.

Significant variables to set in script:
- Hadoop data warehouse server IP address and port number
- Username and Password for data warehouse
- THEA data table name list

- Inputs:
	1) THEA data tables stored on SDC data warehouse
		a. Forward Collision Warning
		b. Emergency Electronic Brake Light Warning
		c. Interseciton Movement Assist Warning
		d. Pedestrian Collision Warning
		e. Vehicle Turning Right in Front of Transit Vehicle Warning
		f. Wrong Way Entry Warning
	2) THEA sent BSM Data stored on SDC data warehouse
	3) THEA received BSM Data stored on SDC data warehouse
	4) THEA PSM data stored on SDC data warehouse
	
- Outputs:
	1) THEA data tables (with corrected dates and times)
		a. Forward Collision Warning
		b. Emergency Electronic Brake Light Warning
		c. Interseciton Movement Assist Warning
		d. Pedestrian Collision Warning
		e. Vehicle Turning Right in Front of Transit Vehicle Warning
		f. Wrong Way Entry Warning
	2) THEA sent BSM Data stored on SDC data warehouse
	3) THEA received BSM Data stored on SDC data warehouse
	4) THEA PSM data stored on SDC data warehouse

## 2. interpBSMData_[event type].py
This script performs interpolations on the BSM data for specific event types. There are six scripts total, one for the 6 "event types" as follows:
	1) FCW
	2) EEBL
	3) IMA
	4) PCW
	5) VTRFTV
	6) WWE

This script is used to fill gaps in BSM data surounding warnings issued to drivers during the THEA CVP deployment period. Gaps in the data range from a few tenths of a second to a few seconds. Volpe's data analysis methodologies relies on having data points every tenth of a second, so this script ensures that the analysis dataset has data points consistently 0.1 second intervals.

 - Inputs:
	1) THEA data table for the "event type" indicated by the script name on SQL server. "Event type" should be one of the following:
		a. FCW
		b. EEBL
		c. IMA
		d. PCS
		e. VTRFTV
		f. WWE
	2) THEA sent BSM Data stored on SDC data warehouse
	3) THEA received BSM Data stored on SDC data warehouse
	4) THEA PSM data stored on SDC data warehouse
	
- Outputs:
	1) Sent BSM data interpolated to 0.1 second intervals
	2) Received BSM data interpolated to 0.1 second intervals

