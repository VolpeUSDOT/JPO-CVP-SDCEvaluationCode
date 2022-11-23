# Connected Vehicle Pilot Safetly Evaluation Data Processing Scripts and Algorithms
This repository stores the scripts and code ussed to process and analyze the data produced by the three pilot sites New York, Tampa, and Wyoming, during the connected vehicle pilot evaluation program. These processes were engineered by two teams: OCIO's Secure Data Commons team who developed and maintained the data intake and curation pipelines (folders 1, 2, and 3 below); and the Volpe Safety Evaluation Team who developed the secondary data processing and analysis algorithms to enable safety evaluation of the data (folders (4, 5, 6, 7, and 8). 

The following folders are available in this repository:
1) **SDC_data_processing**: This folder contains the python code deployed in lambda functions on the SDC that pre-processed raw data files into individual message types and alert records from THEA and NYCDOT Data providers. WYDOT is not included here because there was no pre-processing for WYDOT's CV pilot data on the SDC.
2) **SDC_data_loading**: This folder contains Hive based SQL scripts that loaded the pre-processed data files on the SDC into a relational database structure. 
3) **SDC_data_querying**: This folder contains example SQL scripts and queries to be used on the resulting database structures in the SDC. 
4) **cvp-safety-sql-plugin-master**: This folder contains the C# code and project files used to create the relative kinematics SQL plugin. These functions were used to calculate the relative kinematics between host and target vehicles for the Wyoming and NYC pilot sites. 
5) **VehicleVizualizationTool_V7-8**: This folder contains the vehicle vizualization tool developed by Volpe within the SDC to vizualize and animate the connected vehicle data produced by the pilot sites. 
6) **VolpeEvaluationFiles_NYC**: This folder contains the scripts and alogirithms developed by Volpe to process CV data produced by NYC and stored in SDC's data warehouse. 
7) **VolpeEvaluationFiles_THEA**: This folder contains the scripts and alogirithms developed by Volpe to process CV data produced by THEA and stored in SDC's data warehouse. 
8) **VolpeEvaluationFiles_WYDOT**: This folder contains the scripts and alogirithms developed by Volpe to process CV data produced by WYDOT and stored in SDC's data warehouse. 
