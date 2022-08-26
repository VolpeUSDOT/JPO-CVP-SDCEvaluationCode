# README File for Vehivle Vizualization Event Playback Backend Python Code

## Files
There are two files necessary to run the backend of the code. 
1) eventPlayback.py
2) eventPlaybackBackend.py

### eventPlayback.py
This file sarts up a server that can respond to certain requests. The URIs that
can be used are described in a later section

### eventPlaybackBackend.py
This file defines the URIs and the functionality of the server started by 
'eventPlayback.py.' A number of functions are defined to get configuration 
information, lists of events, data from events, and to issue SQL queries 
directly.

## Functionality
The server will start by defualt on port 5000. All requests should work on 
'localhost:5000.' All URIs return JSON strings with different structures 
depending on the information being returned. The following URIs are enabled:

**/get_site_info**
Returns the configuration of the event database.

Inputs:
- No Inputs

**/get_events/<site>/<event_type>**
Returns all of the event records for a specific type of event in a specific 
site as described in the database configuration. 

Inputs:
- site: the name of the site in the database for which event records should be
pulled. Should match one of the sites listed in the configuration file. 
- event_type: the name of the event type to pull the list of events for. Should
match one of the event types in the configuration file specific to the site 
input.

Returns:
- List of records as structs with each row being a field in the struct

**/get_event_data/<site>/<event_type>/<event_id>**
Returns all of the event data for a specific event id. 

Inputs:
- site: the name of the site in the database for which event records should be
pulled. Should match one of the sites listed in the configuration file. 
- event_type: the name of the event type to pull the list of events for. Should
match one of the event types in the configuration file specific to the site 
input.
- event_id: id of the event for which the data should be returned. 

Returns:
- Struct with elements:
    - event record: the specific event record identified by the event id passed
    passed to the event
    - dependency data: the returned result from all depency tables listed for 
    the site and event in the configuration file. This is the list of structs. 
    The structs will have sub-structs which contain the actual data. The keys 
    of the sub-structs will be the index's of the data, the values will be the 
    data itself. 

**/from_sql/<sql_query>**
Returns results from a query issued to the SQL server directly. 

Inputs:
- sql_query: must be a valid and executable sql query. 

Returns:
- Results of SQL query as JSON string
