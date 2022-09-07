# Volpe Data Processing and Evaluation Code

This "README" file describes the scripts used to process and analyze the NYC connected vehicle data sent to the SDC between 2021-01-01 to 2021-12-31.

## 1. MOVEtoSQL_NYC_V2.py
This script transfers data from the SDC's data warehouse. This script reads data from the NYC pilot data tables stored in the SDC data warehouse. The script transfers New York's event table, the BSM table, the MAP table, and the SPAT table. For each table, the column names are modified from the defaults in the data warehouse to simpler, more easily understandable, and descriptive names.  

MAP and SPaT data are processed slightly differently in this script. MAP data is stored in the SDC data warehouse as a series of relational tables with one record per node in each lane in each intersection in each MAP record. The python data transfer script processes these nodes into singular records per lane in each intersection, storing the lanes as SQL geometry types with a unique ID for the intersection and event in a single table. Similarly, SPaT is stored in separate relational tables with a node for each signal state per approach lane, intersection, and map record for an event. The transfer script combines these tables and renames the table columns into shorter, more understandable names. 

Significant variables to set in script:
- Hadoop data warehouse server IP address and port number
- Username and Password for data warehouse
- NYC Table Names

- Inputs:
	1) Event Record Table
	2) BSM Table
	3) MAP Tables
		a. MAP Core
		b. MAP Intersections
		c. MAP LaneSet
		d. MAP Connectors
		e. MAP Nodes
	4) SPaT Tables
		a. SPaT Core
		b. SPaT Intersections
		c. SPaT States
		d. SPaT ManeuverAssist
		e. SPaT StateTimeSpeed
	
- Outputs:
	1) NYC Event table with dummy times and locations
	2) NYC BSM tables with dummy times and locations
	3) NYC MAP table with combined columns and lane geometries
	4) NYC SPaT table with combined columns

## 2. CreateExperimentGroup_DropTest.sql
This short SQL script creates the experiment group column in the event table for NYC event data. It relies on the "grpid" column to determine if the host vehicle for a particular alert is part of the control or treatment group. Vehicles that are indicated as test vehicles are also removed from the dataset. 
- Input:
	1) NYC warning event table
- Output:
	2) Updated NYC warning event table

## 3. CreateWarningStartTime.sql
This script sets the BSM time at which the warning was triggered within the Event data. This allows vehicle kinematic calculations to be performed by connecting the event data and the BSM data. 
- Input:
	1) NYC warning event table
	2) NYC host vehicle BSM table
- Output:
	1) Updated NYC event table with event triggered time column

## 4. DropDuplicateBSMData.sql
This script deletes duplicate host and target vehicle BSM data. Records are deemed duplicates based on repeated sequence numbers. 
- Input:
	1) NYC host vehicle BSM data
	2) NYC target vehicle BSM data
- Output:
	1) De-duplicated NYC host vehicle BSM data
	2) De-duplicated NYC target vehicle BSM data

## 5. CreateEventDummyLatLongs.sql
Because Volpe's analysis algorithms use latitudes and longitudes, as well as SQL DateTime data types, this script assigns dummy latitude and longitude values using he "X" and "Y" columns, and dummy DateTime objects using the "Time" columns of each table. These do not represent any real longitude or latitude, they just allow geographic kinematic calculations to be performed using Volpe's already developed algorithms for calculating vehicle kinematics. To make dummy values easier to calculate, these latitudes and longitudes are calculated to be near the equator. To ensure there are no errors in later calculation, all dummy latitude an longitude values are placed in a single hemisphere such that they are all positive. 
-Inputs:
	1) NYC event record table
	2) NYC host vehicle BSM data
	3) NYC target vehicle BSM data
-Outputs: 
	1) Event data table updated with dummy latitude and longitude
	2) Host vehicle BSM data table updated with dummy latitude and longitude
	3) Remote vehicle BSM data table updated with dummy latitude and longitude

## 3. register.sql
This script is used to register the C# functions with the SQL Server instance so they can be used with the CV Pilot Data. There is no input or output for this script.

## 4. computedcolumns.sql
This script creates SQL Geometry columns using the latitude and longitude fields of NYC BSM data. It is necessary to run this script before running the Vehicle Kinematics calculations.
- Input:
	1) NYC received and sent BSM data. 
- Output:
	1) Copies of host and target vehicle BSM tables with geometric columns

## 5. VehicleKinematics.sql
The Volpe team developed different vehicle kinematic parameters using the sent and received BSM data to conduct the safety evaluation for CVP safety applications. Detailed descriptions of the calculations performed in this script are summarized in Appendix D (Link to publication). The inputs listed here are taken from the received and sent BSM tables in the NYC database stored on the SDC. The SQL script outputs a new table that contains the kinematic data between host and target vehicles. 
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

## 6. RLVW Data Analysis Scripts 
The following scripts process data from the RLVW application. MAP and SPaT data were only available for these application types, and as such the analysis and data processing for the RLVW data differed from other applications. 

### 6.1 CreateMapLaneGeometry.sql
This script creates an SQL geometry type column using the MAP lane geometries that were created in the data transfer script (script number 1). This script is used specifically for analysis of RLVW alerts. MAP data is not available for any other NYC warning application. 
- Inputs:
	1) Lane Geometry column in NYC MAP table encoded in well-known-text format 
- Outputs:
	1) Updated MAP column with SQL geometry type column

### 6.2 CreateHostVehicleLaneData
This script creates a new table specifically for host vehicle BSM data from RLVW alert events. The queries in this script first create a new table for this BSM data. Then, it uses the X and Y location data from the BSM records to geometrically match the closest lane in the MAP record data for that specific RLVW event. Lane's are only deemed matches if they are at most 3 meters away from the vehicle location at any point in time. 
- Inputs:
	1) NYC host vehicle BSM data
	2) NYC MAP data for RLVW events
- Outputs:
	1) Host vehicle BSM data for RLVW events with lane information specific to that time stamp and vehicle location

### 6.3 SetRLVWStopLine.sql
This script determines which endpoint of the lane in RLVW host vehicle BSM data the vehicle is facing. It uses geometric comparisons to determine which stop line the vehicle is facing at the time specific to that BSM record. The updated RLVW BSM table contains new columns for the X and Y location values for the applicable stop line for that particular point in time. 
- Inputs:
	1) NYC RLVW BSM data
	2) NYC MAP lane data with geometric column for lane geometries
- Outputs:
	1) Updated NYC RLVW BSM data with columns for stop line X and Y coordinates

### 6.4 CreateHostVehicleAlertTimeLaneData.sql
These queries create a copy of the host vehicle RLVW BSM data that replaces the stop lane and lane information in the original RLVW BSM data with the lane that is applicable at the time of the RLVW alert onset. The resulting information relates all vehicle location information in the original host vehicle BSM data to the lane in which the vehicle was located at the time of the alert. This script also joins the vehicle and lane location information with the signal state and timing information from the NYC SPaT data table. The signal states are specific to the lane in which the vehicle was located at the time of the alert at the time indicated in each BSM record. 
- Inputs:
	1) NYC RLVW BSM data with stop line coordinates
	2) NYC alert event data table
	3) NYC SPaT data table
- Outputs:
	1) Updated NYC RLVW BSM data with lane and stop line information at time of alert onset, and signal phase column specific to the time of the BSM data. 

### 6.5 CorrectRLVWVehicleStoplineDummyLocs.sql
In order to prevent errors in later kinematic calculations, dummy latitude and longitude locations of the stop lines in the BSM data created in script 6.4 are corrected such that they fall in a single hemisphere and are all positive. 
- Inputs:
	1) NYC RLVW BSM data produced in script 6.4
- Outputs:
	1) Updated NYC RLVW BSM data with corrected dummy latitudes and longitudes

### 6.6 RLVWcomputedcolumns.sql
This script creates SQL Geometry columns using the latitude and longitude fields of NYC BSM data specifically for RLVW alert events. It is necessary to run this script before running the RLVW vehicle kinematics calculations.
- Input:
	1) NYC received and sent BSM data. 
- Output:
	1) Copies of host and target vehicle BSM tables with geometric columns

### 6.7 RLVWKinematics.sql
Similar to the previously listed vehicle kinematics calculation script (script 5), this script calculates relative kinematics between the stop line and the host vehicle during an RLVW event. Summaries of the equation and parameters calculated are available in Appendix D of the final NYC report (Link to publication).
- Input:
	1) Date/Time
	2) Latitude
	3) Longitude
	4) Heading
	5) Speed
	6) Longitudinal Acceleration
	7) Lateral Acceleration	
- Outputs:
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

## 7. Safety Evaluation and Alert Validation Algorithms
The following scripts validate and analyze data specific to each NYC alert application type. The resulting tables and variables summarize the relative positioning between the the host and target vehicles or infrastructure at the time of the alert and the driver response after the alert. The parameters that summarize these vehicle states change depending on the alert type. The summarized values can be statistically analyzed to determine safety effectiveness and operational changes between control and treatment group vehicles. 

### 7.1  NYC_FCW_Event.SQL
There are three algorithms for this safety application. The first algorithm validates the FCW target position and identifies its driving states and its experimental group. The second algorithm identifies good data and captures the FCW alerts where the host vehicle is at risk of colliding with the vehicle in front of it. The third algorithm updates vehicles which have erroneous speed data. The FCW conflicts are determined using a combination of BSM data and computed kinematics data.
- Inputs:
	1) BSM data
	2) Kinematics data
- Outputs:
	1) Variables required to determine the presence of a FCW conflict include:
	 	a. Lead vehicle event
		b. Braking intensity
		c. TTC
		d. Range
		e. Range rate
		f. Headway
	2) FCW conflicts validate using the visualization tool. The metrics used to assess driver response to FCW conflict include:
		a. TTC at brake onset
		b. Minimum TTC
		c. Peak deceleration
		d. Average deceleration 
		e. Headway time at brake onset

### 7.2 NYC_[Event Type]\_Event.SQL
(Replace "Event Type" with one of IMA, BSW, LCW, or EEBL)

These scripts cover analysis of IMA, BSW, LCW, and EEBL alert data. These three scripts each contain two algorithms. The first algorithm validates the vehicles heading, and identifies road geometry, target driving states, relative distances between host and target vehicles, and experimental group. The second algorithm identifies good data and captures the alert scenarios where the host vehicle is at risk of colliding with target vehicle. These conflicts are determined using a combination of BSM data and computed kinematics data. The outputs listed here may be different in each script depending on the specific event type. 
- Inputs:
	1) BSM data
	2) Kinematics data
- Outputs:
	1) Variables required to determine the presence of conflict include:
		a. HV and RV Speeds
		b. Braking intensity
		c. HV and RV relative positions and TTIs
		d. Lateral and Longitudinal Ranges
		e. TTC
		f. Range
		g. Range rate
		e. Headway
	2) The metrics used to assess driver response to conflicts include:
		a. TTI at brake onset
		b. Minimum TTI
		c. Peak deceleration
		d. Average deceleration
		e. Headway time at brake onset

### 7.3 NYC_RLVW_Event.sql
There is one algorithm for this safety application. This algorithm validates the RLVW vehicles heading and location, identifies traffic light status and relative distances between host vehicles and stop line at an intersection, and the vehicle experimental group. This algorithm also identifies good data and captures the RLVW alert scenarios where the host vehicle is at risk of running a red light. The RLVW conflicts are determined from a combination of BSM/Spat/Map data and computed kinematics data.
- Inputs:
	1) BSM data
	2) Spat and Map data
	3) Kinematics data
- Outputs:
	1) Variables require to determine the presence of RLVW conflict include:
		a. HV Speeds
		b. Braking intensity
		c. HV relative position respect to intersection and TTI
		d. Longitudinal range to intersection
		e. Traffic light status 
	2) The metrics use to assess driver response to RLVW conflict include:
		a. TTI at brake onset
		b. Minimum TTI
		c. Enter intersection signal status

### 7.4 NYC_ SpeedConpliance_Event.sql
This algorithm validates the HV is approaching a speed over the recommended speed. The SpeedConpliance conflicts are determined from the BSM data. 
- Inputs:
	1) BSM data
- Outputs:
	1) Variables required to determine the presence of SpeedConpliance conflict include:
		a. HV Speeds
		b. Braking intensity
	2) The metrics used to assess driver response to SpeedConpliance conflict include:
		a. Brake reaction time
		b. Mean/min/max speed and deceleration
		c. Driver compliance time

## 7.5 NYC_ WorkzoneConpliance_Event.sql
This algorithm validates the HV is approaching an excessive speed for a work zone. The WorkzoneConpliance conflicts are determined from the BSM data. 
- Inputs:
	1) BSM data
- Outputs:
	1) Variables required to determine the presence of WorkzoneConpliance conflict include:
		a. HV Speeds
		b. Braking intensity
	2) The metrics used to assess driver response to WorkzoneConpliance conflict include:
		a. Brake reaction time
		c. Mean/min/max speed and deceleration

