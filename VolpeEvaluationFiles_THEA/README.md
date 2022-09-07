# Volpe Data Processing and Evaluation Code

This "README" file describes the scripts used to process and analyze the THEA connected vehicle data sent to the SDC between 2019-06-01 to 2020-07-01.

## 1. TransferEventData.py
This script transfers data from the SDC's data warehouse. This script reads data from the tables in the list of table names where THEA's warning data is stored. Due to the way date's are encoded in the original data streams, some dates stored in the SDC's data warehouse are erroneous. Therefore, this transfer script attempts to recognize these erroneous dates and times and correct them, improving the quality of the resultant data.

Significant variables to set in script:
- Hadoop data warehouse server IP address and port number
- Username and Password for data warehouse
- THEA data table name list

- Inputs:
	1) THEA data tables stored on SDC data warehouse
		a. Forward Collision Warning
		b. Emergency Electronic Brake Light Warning
		c. Intersection Movement Assist Warning
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
		c. Intersection Movement Assist Warning
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

This script is used to fill gaps in BSM data surrounding warnings issued to drivers during the THEA CVP deployment period. Gaps in the data range from a few tenths of a second to a few seconds. Volpe's data analysis methodologies relies on having data points every tenth of a second, so this script ensures that the analysis dataset has data points consistently at 0.1 second intervals.

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

## 3. register.sql
This script is used to register the C# functions with the SQL Server instance so they can be used with the CVPilot Data. There is no input or output for this script.

## 4. computedcolumns.sql
This script creates SQL Geometry columns using the latitude and longitude fields of THEA BSM data. It is necessary to run this script before running the Vehicle Kinematics calculations.
- Input:
	1) THEA received and sent BSM data. 
- Output:
	1) Copies of BSM tables with geometric columns

## 5. VehicleKinematics.sql
The Volpe team developed different vehicle kinematic parameters using the sent and received BSM data to conduct the safety evaluation for CVP safety applications. Detailed descriptions of the calculations performed in this script are summarized in Appendix D https://rosap.ntl.bts.gov/view/dot/61972/dot_61972_DS1.pdf. The inputs listed here are taken from the received and sent BSM tables in the THEA database stored on the SDC. The SQL script outputs a new table that contains the kinematic data between host and remote vehicles. 
-	Input:
	1) Date/Time
	2) Latitude
	3) Longitude
	4) Heading
	5) Speed
	6) Longitudinal Acceleration
	7) Lateral Acceleration	
-	Outputs:
	1) Range
	2) Range Rate
	3) Time-To-Collision (TTC)
	4) Longitudinal Range
	5) Latitudinal Range
	6) Time-To-Intersection (TTI) (for perpendicularly approaching vehicles)
	7) Relative target vehicle location (Front, back, side)
	8) Relative target lane position (in lane, adjacent)
	9) Relative Distance to Point of Interest (e.g., crosswalk or intersection)
   	10) Time To Point of Interest

## 6. THEA_V2V_Exposure.SQL
This algorithm derives and analyzes information regarding the exposure of equipped vehicles to other equipped vehicles (i.e., V2V interactions) which allows the safety applications to issue alerts to HVs as designed. The inputs to this script are columns in the BSM tables in the THEA data stored on the SDC.
- Inputs:
	1) Host and remote vehicle headings
	2) Host and remote vehicle elevations
	3) Longitudinal and lateral ranges between host and remote vehicles
	4) Relative remote vehicle location 
- Output:
	1) Timing per V2V safety application

## 7. THEA_V2I_Exposure.SQL
This algorithm derives and analyzes information regarding the exposure of equipped vehicles to other equipped infrastructure locations (i.e., V2I interactions), which allows the safety applications to issue alerts to HVs as designed.
- Inputs:
	1) Host and remote GPS
	2) Obtained geo-fence the equipped infrastructure locations
	3) Host vehicle heading
- Output:
	1) Frequency per V2I safety applications

## 8.  THEA_[event type]\_Event.sql

These algorithms capture the validated alert scenarios where the host vehicle is at risk of colliding with the vehicle in front of it. The V2V event conflicts are derived from the raw event data with a combination of BSM fields and event fields (alert flag). The specific BSM data fields used in these algorithms vary by the event type. The "event types" are as follows:
 	1) FCW
	2) EEBL
	3) IMA
	4) PCW
	5) VTRFTV
	6) WWE
- Input:
	1) Event logger
	2) BSM data
	3) Kinematics data
- Outputs:
	- Variables required to determine the presence of a FCW conflict include:
		1) Lead vehicle event
		2) Braking intensity
		3) TTC
		4) Minimum TTC
		4) Range
		5) Range rate
		6) Headway
	- Event conflicts validated using the visualization tool. The metrics used to assess driver response to FCW conflict include:
		1) TTC at brake onset
		2) Minimum TTC
		3) Peak deceleration
		4) Average deceleration 
		5) Headway time at brake onset

