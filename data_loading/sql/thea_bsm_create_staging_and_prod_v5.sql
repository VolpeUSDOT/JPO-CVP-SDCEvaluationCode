DROP TABLE IF EXISTS thea_bsm_staging_v5;

CREATE EXTERNAL TABLE IF NOT EXISTS thea_bsm_staging_v5 (
  metadata struct<
    schemaversion:int,
    recordgeneratedby:string,
    recordgeneratedat:string,
    kind:string,
    bsmsource:string,
    psid:string,
    rsuid:string,
    externalid:string,
    datatype:string,
    logfilename:string
  >,
  payload struct<
    data:struct<
        coredata:struct<
            msgcnt:int,
            id:string,
	          secMark:string,
	          lat: string,
	          long: string,
	          elev: string,
            accuracy:struct<
	              semimajor:string,
                semiminor:string,
                orientation:string
	          >,
            transmission:struct<
                forwardgears:string
            >,
            speed:string,
            heading:string,
	    angle:string,
            accelset:struct<
	        long:string,
                lat:string,
                vert:string,
                yaw:string
	    >,
            brakes:struct<
                wheelbrakes:string,
                traction:struct<
                    unavailable:string    
                >,
                abs:struct<
		    unavailable:string
  		>,
		scs:struct<
                    unavailable:string
                >,
		brakeboost:struct<
                    unavailable:string
                >,
		auxbrakes:struct<
                    unavailable:string
                >
            >,
	    size:struct<
		    width:string,
		    length:string
	    >
       >,
       partII:struct<
           sequence:array<
      			struct<
      			    partiiid:string,
      			     partiivalue:struct<
      			         vehiclesafetyextensions:struct<
      				          pathhistory:struct<
      				            crumbdata:struct<
      					           pathhistorypoint:array<
      								        struct<
          								      latoffset:string,
          								      lonoffset:string,
          								      elevationoffset:string,	
          								      timeoffset:string		
      								        >
      					            >
      					          >
      				          >,
                        pathprediction:struct<
                          radiusofcurve:string,
                          confidence:string
                        >
      				        >,
				              supplementalvehicleextensions:struct<
				                classification:string,
                          classdetails:struct<
                            role:struct<
                              basicvehicle:string
                            >,
					                  hpmstype:struct<
                              car:string
                            >
                          >,
				                  vehicledata:struct<
					                   height:string,
					                   bumpers:struct<
                							front:string,
                							rear:string
					                   >,
					                   mass:string
				                  >
                        >
			                >		   
		              	>
	                >
                >
              >
            >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  "ignore.malformed.json" = "true",
   "mapping.partiiid"="partii-id",
   "mapping.partiivalue"="partii-value"
)

LOCATION
-- 's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/archive/BSM/';
  's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/BSM/';

CREATE TABLE IF NOT EXISTS thea_bsm_v5 (
  metadata struct<
    schemaversion:int,
    recordgeneratedby:string,
    recordgeneratedat:string,
    kind:string,
    bsmsource:string,
    psid:string,
    rsuid:string,
    externalid:string,
    datatype:string,
    logfilename:string
  >,
  payload struct<
    data:struct<
        coredata:struct<
            msgcnt:int,
            id:string,
            secMark:string,
            lat: string,
            long: string,
            elev: string,
            accuracy:struct<
                semimajor:string,
                semiminor:string,
                orientation:string
            >,
            transmission:struct<
                forwardgears:string
            >,
            speed:string,
            heading:string,
      angle:string,
            accelset:struct<
          long:string,
                lat:string,
                vert:string,
                yaw:string
      >,
            brakes:struct<
                wheelbrakes:string,
                traction:struct<
                    unavailable:string    
                >,
                abs:struct<
        unavailable:string
      >,
    scs:struct<
                    unavailable:string
                >,
    brakeboost:struct<
                    unavailable:string
                >,
    auxbrakes:struct<
                    unavailable:string
                >
            >,
      size:struct<
        width:string,
        length:string
      >
       >,
       partII:struct<
           sequence:array<
            struct<
                partiiid:string,
                 partiivalue:struct<
                     vehiclesafetyextensions:struct<
                        pathhistory:struct<
                          crumbdata:struct<
                           pathhistorypoint:array<
                              struct<
                                latoffset:string,
                                lonoffset:string,
                                elevationoffset:string, 
                                timeoffset:string   
                              >
                            >
                          >
                        >,
                        pathprediction:struct<
                          radiusofcurve:string,
                          confidence:string
                        >
                      >,
                      supplementalvehicleextensions:struct<
                        classification:string,
                          classdetails:struct<
                            role:struct<
                              basicvehicle:string
                            >,
                            hpmstype:struct<
                              car:string
                            >
                          >,
                          vehicledata:struct<
                             height:string,
                             bumpers:struct<
                              front:string,
                              rear:string
                             >,
                             mass:string
                          >
                        >
                      >      
                    >
                  >
                >
              >
            >
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 TBLPROPERTIES (
   'orc.compress'='Zlib');

