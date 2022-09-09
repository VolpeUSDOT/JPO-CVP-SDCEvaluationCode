# Connected Vehicle Pilot Safetly Evaluation Data Processing Scripts and Algorithms
This repository stores the scripts and code ussed to process and analyze the data produced by the three pilot sites New York, Tampa, and Wyoming, during the connected vehicle pilot evaluation program. These processes were produced by two teams: OCIO's Secure Data Commons team who developed and maintained the data intake and curation pipelines; and the Volpe Safety Evaluation Team who developed the data processing the analysis algorithms to enable safety evaluation of the data. 

The following folders are available in this repository:
1) **cvp-safety-sql-plugin-master**: This folder contains the C# code and project files used to create the relative kinematics SQL plugin. These functions were used to calculate the relative kinematics between host and target vehicles for the Wyoming and NYC pilot sites. 
2) **VehicleVizualizationTool_V7-8**: This folder contains the vehicle vizualization tool developed by Volpe within the SDC to vizualize and animate the connected vehicle data produced by the pilot sites. 
3) **VolpeEvaluationFiles_NYC**: This folder contains the scripts and alogirithms developed by Volpe to process CV data produced by NYC and stored in SDC's data warehouse. 
4) **VolpeEvaluationFiles_THEA**: This folder contains the scripts and alogirithms developed by Volpe to process CV data produced by THEA and stored in SDC's data warehouse. 
5) **VolpeEvaluationFiles_WYDOT**: This folder contains the scripts and alogirithms developed by Volpe to process CV data produced by WYDOT and stored in SDC's data warehouse. 
