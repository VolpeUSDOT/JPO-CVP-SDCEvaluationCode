--------------------------------------------------------------
-- Create the THEA_TIM_STAGING table 
--------------------------------------------------------------
DROP TABLE IF EXISTS thea_tim_staging;

CREATE EXTERNAL TABLE if not exists thea_tim_staging (
  metadata struct<
    	datatype:string, 
    	kind:string, 
    	logfilename:string, 
    	psid:string, 
    	recordgeneratedat:string, 
    	recordgeneratedby:string, 
    	rsuid:string, 
    	schemaversion:int
  >,
  payload struct<
      data:struct<
  		TravelerInformation:struct<
  			msgCnt:int,
            timeStampTravelerInformation:int,   -- not in THEA sample (optional)
  			packetID:string,
  			dataFrames:struct<
				TravelerDataFrame:array<struct< -- TravelerDataFrame is an array in THEA
					-- Part I, Frame header
  					sspTimRights:int,
  					frameType:string,           -- struct type, but cast to STRING 
  					msgId:struct<               
  						roadSignID:struct<
  							position:struct<
  								lat:int,
  								long:int,
  								elevation:int						
  							>,
  							viewAngle:bigint,
  							mutcdCode:struct<
  								warning:string
  							>
  						>
  					>,
  					startYear:int,
  					startTime:int,
  					durationTime:int,
  					priority:int,
					-- Part II, Applicable Regions of Use
  					sspLocationRights:int,
                    regions:struct<      
                        GeographicalPath:struct<
                            name:string,  -- not in THEA sample (optional)
                            id:struct<    -- not in THEA sample (optional)
                                region:int,
                                id:int
                            >,
                            anchor:struct<
                                lat:int,
                                long:int,
                                elevation:int											
                            >,
                            laneWidth:int,
                            directionality:string, -- struct but cast to string
                            direction:bigint,
                            description:struct<    
                                path:struct<
                                    offset:struct< 
                                        xy:struct< 
                                            nodes:struct<
                                                NodeXY:array<
                                                    struct<
                                                        delta:struct<
                                                            nodexy1:struct<
                                                                x:int,
                                                                y:int
                                                            >,
                                                            nodexy2:struct<
                                                                x:int,
                                                                y:int
                                                            >,
                                                            nodexy3:struct<
                                                                x:int,
                                                                y:int
                                                            >,
                                                            nodexy4:struct<
                                                                x:int,
                                                                y:int
                                                            >,
                                                            nodexy5:struct<
                                                                x:int,
                                                                y:int
                                                            >,
                                                            nodexy6:struct<
                                                                x:int,
                                                                y:int
                                                            >,
                                                            nodelatlon:struct<
                                                                lon:bigint,
                                                                lat:bigint
                                                            >
                                                        >,
                                                        attributes:struct<
                                                            dWidth: int,    
                                                            dElevation: int		
                                                        >
                                                    >
                                                > --NodeXY:array
                                            > --nodes:struct<
                                        > --xy:struct<									
                                    > --offset:struct
                                > --path:struct<													
                            > --description:struct<
                        > --GeographicalPath:struct<
                    >, -- closing bracket for regions
					-- Part III, Content
  					sspMsgRights1:int,
  					sspMsgRights2:int,
  					content:struct<   
  						advisory:struct<
  							SEQUENCE:array<
  								struct<
  									item:struct<
  										itis:int 
  									>
  								>
  							>
  						>,
  						genericSign:struct<
  							SEQUENCE:array<
  								struct<
  									item:struct<
  										itis:int
  									>
  								>
  							>
  						>,
  						speedLimit:struct<
  							SEQUENCE:array<
  								struct<
  									item:struct<
  										itis:int
  									>
  								>
  							>
  						>
  					> --content:struct<			
				>> -- closing brackets for TravelerDataFrame:array<struct<
			>
		>
	>
  >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
   "ignore.malformed.json" = "true",
   "mapping.durationtime" = "duratonTime",  -- typo in SAE J2735
   --"mapping.SEQUENCE" = "SEQUENCE",
   "mapping.nodexy1" = "node-xy1",
   "mapping.nodexy2" = "node-xy2",
   "mapping.nodexy3" = "node-xy3",
   "mapping.nodexy4" = "node-xy4",
   "mapping.nodexy5" = "node-xy5",
   "mapping.nodexy6" = "node-xy6",
   "mapping.nodelatlon" = "node-latlon",
   "mapping.timestamptravelerinformation" = "timestamp"
)
LOCATION
	's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/thea/TIM/';

--------------------------------------------------------------
-- Create the THEA_TIM table 
--------------------------------------------------------------
CREATE TABLE IF NOT EXISTS thea_tim 
	LIKE thea_tim_staging 
	STORED AS ORC tblproperties("orc.compress"="Zlib");
