# Data Loading SQL Examples

## Introduction

The sql subfolder contains sets of HiveQL (SQL Hive-specific variation) scripts for loading data from WYDOT, THEA, and NYCDOT message data files into a Hive/Hadoop data warehouse. 

Each message type data set has corresponding sql scripts that as a group conform to the following naming convention:

**<data_set_name>_create_staging.sql**: script to create a staging table based on an s3 storage location

**<data_set_name>_prod.sql**: script to insert data into a pre-production data table during nightly data load

**<data_set_name>_drop_staging.sql**: script to drop a staging table

**relational/<data_set_name>_rel_prod_insert.sql**: script to insert data into a production data table incrementally during nightly data load

**relational/<data_set_name>_rel_prod.sql**: script to recreate and fully reload a data table


## Data Loading Steps
For the purpose of this write up, we will use WYDOT BSM data set as an example.

As such, the following scripts will be discussed:
```
wydot_bsm_create_staging.sql
wydot_bsm_prod.sql
relational/wydot_bsm_rel_prod.sql
wydot_bsm_drop_staging.sql
```

### Prerequisites ###

One or more data file with messages of specific type exist at a designated AWS S3 bucket location.

### 1. wydot_bsm_create_staging.sql ###

This is the first step for reloading data. We utilize ability of Hadoop data warehouse to create data tables directly from S3 locations.

### 2. wydot_bsm_prod.sql ###

This script creates and populates a set of non-relational tables that will be utilized later in the process in order to create relational ones for easier querying.

### 3. relational/wydot_bsm_rel_prod.sql ###

This script creates and populates a set of relational tables for data analysis.

### 4. wydot_bsm_drop_staging.sql ###

Cleanup: removal of staging tables.








