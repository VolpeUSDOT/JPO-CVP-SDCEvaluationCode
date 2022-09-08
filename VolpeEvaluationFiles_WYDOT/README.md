# Volpe Data Processing and Evaluation Code

This "README" file describes the scripts used to process and analyze the WYDOT connected vehicle data sent to the SDC between 2022-01-01 to 2022-4-30.

## 1. MOVEtoSQL_WYDOT_V2.py
This script transfers data from the SDC's data warehouse. This script reads data from the WYDOT pilot data tables stored in the SDC data warehouse. The script transfers FCW data from Wyoming's Alert table, traveler information alert messages from the Alert table, Speed sensor data, and BSM data surounding the FCW alerts. For each dataset, the column names are modified from the defaults in the data warehouse to simpler, more easily understandable, and descriptive names.  

For the traveler information alerts, this script translates ITIS codes in the WYDOT alert table to the english meaning. This requires an excel spreadsheet that lists the exact ITIS codes that should be translated and the appropriate translation. The spreadsheet also contains a column that categorizes the ITIS code into a sub-category that groups certain types of alerts together, and an application column that that matches the ITIS code with the application type that was deployed by WYDOT. 

Significant variables to set in script:
- Hadoop data warehouse server IP address and port number
- Username and Password for data warehouse
- WYDOT Table Names
- Destination database information

- Inputs:
	1) Alert Record Table
	2) BSM Table
	3) Speed Table
	4) ITIS code listing spreadsheet
	
- Outputs:
	1) WYDOT FCW table
	2) WYDOT BSM table for FCW data
	3) WYDOT Traveler Alert Table
	4) WYDOT Speed Sensor Data

## 2. WYDOT_Speed_Data.SQL
This algorithm isolates individual speed sensor data in WYDOT's speed data in before and after periods, and separates by time of day. It also creates an index to indicate whether each record was generated in the before or after period and calculates speed differential and headway between each speed record and the vehicle in front of it (lane dependent) if vehicles are traveling within a certain distance/time of each other.
- Input:
	1) Vehicle Speed Data
-	Output:
	1) Headway
	2) Speed differential
	3) Speed over/under limit speed

## 3.  WYDOT_FCW_Event.SQL
This algorithm generate the following:
-	Range, range-rate between the HV and RV, and time to collision
-	Distinct FCW events
-	Filtering of data issues and invalid FCW events
-	Initial conditions at FCW alert onset
-	Driver response to FCW alerts
Inputs and outputs are as follows:	
- Inputs:
	1) BSM and event data
- Outputs:
	1) Variables require to determine the presence of a FCW conflict include:
		a. Lead vehicle event
		b. Braking intensity
		c. TTC
		d. Range
		e. Range rate
		f. Headway
	2) FCW conflicts validate using the visualization tool. The metrics use to assess driver response to FCW conflict include:
		a. TTC at brake onset
		b. Minimum TTC
		c. Peak deceleration
		d. Average deceleration 
		e. Headway time at brake onset

