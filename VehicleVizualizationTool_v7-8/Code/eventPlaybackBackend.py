from flask import Flask, render_template
import pandas as pd
import sqlalchemy
import json

MSSQLEngine = sqlalchemy.create_engine('mssql+pyodbc://' #Driver
                                       '@' #Username:Password
                                       'ECSPWVOL01/master' #Server IP
                                       '?driver=SQL+Server&'
                                       'trusted_connection=yes') #driver name

app = Flask(__name__)

# Do this outside our functions so it is global
with open('./configuration.json') as configFile:
        config = json.load(configFile)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/get_site_info')
def get_site_info():
    #Returns the info about sites, event types, and table names
    
    with open('./configuration.json') as configFile:
        config = json.load(configFile)
    
    return json.dumps(config)
    
@app.route('/get_events/<site_name>/<event_type>')
def get_events(site_name, event_type):
    for site in config['sites_details']:
        if site['site_name'] == site_name:
            for table in site['event_tables']:
                if table['event_type'] == event_type:
                    try: 
                        warnings = pd.read_sql("select * from {}.dbo.{} where {} = '{}'".format(site['schema_name'], table['table_name'], table['event_type_column_name'], event_type), con=MSSQLEngine)
                        idStringDict = {table['id_column_name']:'str'}
                        
                        warningsIDStrings = warnings.astype(idStringDict)
                        #print(warningsIDStrings.dtypes) 
                        #print(warnings.to_json(orient='records', date_format='iso', double_precision=15))
                        warningsIDStrings.rename(columns={\
                                                        'eventid': 'orig_eventid',
                                                        #table['id_column_name']: 'eventid',
                                                        table['event_time_column_name']: 'metadataloggeneratedat',
                                                        table['host_id_column_name']: 'metadatahostvehicleid',
                                                        table['remote_id_column_name']: 'rvbsmid',
                                                        table['host_lat_column_name']: 'hvbsmlat',
                                                        table['host_long_column_name']: 'hvbsmlong'},
                                                inplace=True)
                        warningsIDStrings['hvbsmlat'] = warningsIDStrings['hvbsmlat']* 10000000.00
                        warningsIDStrings['hvbsmlong'] = warningsIDStrings['hvbsmlong']* 10000000.00
                        print(warningsIDStrings.columns)
                        warningsIDStrings.sort_values(by=table['id_column_name'], inplace=True)
                        return warningsIDStrings.to_json(orient='records', date_format='iso', double_precision=15)
                    except sqlalchemy.exc.ProgrammingError as e:
                        eString = str(e)
                        toReturn = {"error_code":"SQL Server Error", "error_description":eString}
                        return json.dumps(toReturn)
                    
                
            return json.dumps({"error_code":"Data Not Found", "error_description":"The requested event table is not configured"})
    return json.dumps({"error_code":"Data Not Found", "error_description":"The requested site is not configured"})

#@app.route('/get_event_data/<site_name>/<event_type>/<event_id>/<lower_time_bound>/<upper_time_bound>')
#def get_event_data(site_name, event_type, event_id, lower_time_bound, upper_time_bound):
@app.route('/get_event_data/<site_name>/<event_type>/<event_id>')
def get_event_data(site_name, event_type, event_id):
#    try:
#        lower = int(lower_time_bound)
#        upper = int(upper_time_bound)
#    except ValueError as e:
#        eString = str(e)
#        toReturn = {"error_code":"Input Error", "error_description":eString}
#        return json.dumps(toReturn)
                                    
    for site in config['sites_details']: 
        if site['site_name'] == site_name:
            for table in site['event_tables']:
                print(table['event_type'])
                print(event_type)
                if table['event_type'] == event_type:
                    try: 
                        eventResult = pd.read_sql( \
                            "select * from {}.dbo.{} \
                             where {} = '{}' and {} = '{}'" \
                            .format(site['schema_name'], table['table_name'],  table['id_column_name'], event_id, table['event_type_column_name'], event_type), \
                            con=MSSQLEngine)
                    except sqlalchemy.exc.ProgrammingError as e:
                        eString = str(e)
                        toReturn = {"error_code":"SQL Server Error", "error_description":eString}
                        return json.dumps(toReturn)
                    if len(eventResult) != 1:
                        toReturn = {"error_code":"Event Error", "error_description":"The event id was not found or was not unique"}
                        return json.dumps(toReturn)
                    eventResult.rename(columns={\
                                                        table['event_time_column_name']: 'metadataloggeneratedat',
                                                        table['host_id_column_name']: 'metadatahostvehicleid',
                                                        table['remote_id_column_name']: 'rvbsmid',
                                                        table['host_lat_column_name']: 'hvbsmlat',
                                                        table['host_long_column_name']: 'hvbsmlong'},
                                                inplace=True)
                    eventResult['hvbsmlat'] = eventResult['hvbsmlat']* 10000000.00
                    eventResult['hvbsmlong'] = eventResult['hvbsmlong']* 10000000.00
                    eventRecord = eventResult.iloc[0]
                    eventRecordDict = json.loads(eventRecord.to_json(date_format='iso', double_precision=15))
                    event_data = {"event_record": eventRecordDict}
                    dependData = []
                    for dependTable in table['dependency_tables']:
                        try: 
                            dataTableResult = pd.read_sql( \
                                "select * from {}.dbo.{} \
                                where {} = '{}' and {} = '{}' \
                                order by {} asc" \
                                .format(site['schema_name'], dependTable['dependency_name'],  table['id_column_name'], event_id, dependTable['event_type_column_name'], event_type, dependTable['datetime_column_name']), \
                                con=MSSQLEngine)
                        except sqlalchemy.exc.ProgrammingError as e:
                            eString = str(e)
                            toReturn = {"error_code":"SQL Server Error", "error_description":eString}
                            return json.dumps(toReturn)
                        dataTableResult.rename(columns={\
                                                        dependTable['datetime_column_name']: 'datetimestamp',
                                                        dependTable['lat_column_name']: 'coredatalat',
                                                        dependTable['long_column_name']: 'coredatalong',
                                                        dependTable['heading_column_name']: 'coredataheading'
                                                        },\
                                                inplace=True)
                        #dataTableResult = dataTableResult[['datetimestamp', 'coredatalat', 'coredatalong', 'coredataheading']]
                        dataTableResult = dataTableResult.dropna().reset_index()
                        print(dataTableResult['datetimestamp'])
                        dataDict = json.loads(dataTableResult.to_json(date_format='iso', double_precision=15))
                        dataDict["table_name"] = dependTable['dependency_name']
                        dependData.append(dataDict)
                    event_data['dependency_data'] = dependData
                    
                    return json.dumps(event_data)
                    
            return json.dumps({"error_code":"Data Not Found", "error_description":"The requested event table is not configured"})
    return json.dumps({"error_code":"Data Not Found", "error_description":"The requested site is not configured"})

@app.route('/from_sql/<query>')
def from_sql(query):
    try:
        data = pd.read_sql(query)
        return data.to_json(orient='records', date_format='iso', double_precision=15)
    except sqlalchemy.exc.ProgrammingError as e:
        eString = str(e)
        toReturn = {"error_code":"SQL Server Error", "Exception":eString}
        return json.dumps(toReturn)