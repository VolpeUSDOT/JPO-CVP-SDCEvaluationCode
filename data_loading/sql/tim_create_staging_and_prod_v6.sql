--------------------------------------------------------------
-- Create a staging table for TIM schema version 6
--------------------------------------------------------------
DROP TABLE IF EXISTS wydot_tim_staging_v6;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_tim_staging_v6 (
    metadata struct<
        request:struct<
            ode:struct<
                verb:string,
                version:int
            >,
            sdw:struct<
                recordId:string,
                serviceRegion:struct<
        					nwCorner:struct<
        						latitude:float,
        						longitude:float
        					>,
        					seCorner:struct<
        						latitude:float,
        						longitude:float
        					>
				        >,
                ttl:string
            >,
			rsus:array<struct<
				rsus:struct<
					rsuTarget:string,
					--rsuUsername:string,
					rsuRetries:int,
					rsuTimeout:int,
					--rsuPassword:string, --omitting on purpose.
					rsuIndex:int
				>>
			>,
            snmp:struct<
                mode:int,
                deliverystop:string,
                rsuid:string,
                deliverystart:string,
                enable:int,
                channel:int,
                msgid:int,
                snmpInterval:int,
                status:int
            >
        >,
        securityResultCode:string, 
        recordGeneratedBy:string,
        receivedMessageDetails:struct< 
            locationData:struct< 
                elevation:float, 
                heading:string, 
                latitude:float, 
                speed:float, 
                longitude:float 
            >,
            rxSource:string 
        >,
        schemaVersion: int,
        payloadType:string,
        validSignature:boolean, 
        serialId:struct<
            recordId:int,
            serialNumber:int,
            streamId:string,
            bundleSize:int,
            bundleId:int
        >,
        sanitized:boolean,
        recordGeneratedAt:string,
        recordType:string, 
        logFileName:string, 
        odeReceivedAt:string
    >,
    payload struct<
        data:struct<
            MessageFrame:struct<
                messageId:int,
                value:struct<
                    TravelerInformation:struct<
                        timeStampTravelerInformation:int,
                        packetID:string,
                        urlB:string,
                        dataFrames:struct<
                            TravelerDataFrame:struct<
                                regions:string,   -- struct type, but cast to STRING in Restructring
                                durationTime:int,
                                sspMsgRights1:int,
                                sspMsgRights2:int,
                                sspTimRights:int,
                                startYear:int,
                                sspLocationRights:int,
                                frameType:string, -- struct type, but cast to STRING in Restructring
								--struct<
        --                            unknown:string,
        --                            advisory:string,
        --                            roadSignage:string, 
        --                            commercialSignage:string
        --                        >,
                                msgId:struct<
                                    roadSignID:struct<
                                        crc:string, 
                                        viewAngle:bigint,
                                        mutcdCode:struct<
                                            warning:string
                                        >,
                                        position:struct<
                                            elevation:int, 
                                            lat:int,
                                            long:int
                                        >
                                    >
                                >,
                                startTime:int,
                                priority:int,
                                content:struct<
                                    advisory:struct<
                                        sequenceAdvisory:array<
                                            struct<
                                                item:struct<
                                                    itis:int,
													text:string  -- added in Restructring
                                                >
                                            >
                                        >
                                    >
                                >,
                                url:string
                            >
                        >,
                        msgCnt:int
                    >
                >
            >
        >,
        dataType:string
    >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
   "ignore.malformed.json" = "true",
   "mapping.snmpinterval" = "interval",
   --"mapping.falseclosedpath" = "false",
   --"mapping.trueclosedpath" = "true",
   --"mapping.bothdirectionality" = "both",
   --"mapping.forwarddirectionality" = "forward",
   --"mapping.reversedirectionality" = "reverse",
   "mapping.durationtime" = "duratonTime",  -- typo in SAE J2735
   "mapping.sequenceadvisory" = "SEQUENCE",
   "mapping.timestamptravelerinformation" = "timestamp"
)
LOCATION
    --'s3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/TIM/v6/';
      's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/TIM/';

--------------------------------------------------------------
-- Create a table for TIM schema version 6
--------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wydot_tim_v6 (
    metadata struct<
        request:struct<
            ode:struct<
                verb:string,
                version:int
            >,
            sdw:struct<
                recordId:string,
                serviceRegion:struct<
        					nwCorner:struct<
        						latitude:float,
        						longitude:float
        					>,
        					seCorner:struct<
        						latitude:float,
        						longitude:float
        					>
				        >,
                ttl:string
            >,
			rsus:array<struct<
				rsus:struct<
					rsuTarget:string,
					--rsuUsername:string,
					rsuRetries:int,
					rsuTimeout:int,
					--rsuPassword:string, --omitting on purpose.
					rsuIndex:int
				>>
			>,
            snmp:struct<
                mode:int,
                deliverystop:string,
                rsuid:string,
                deliverystart:string,
                enable:int,
                channel:int,
                msgid:int,
                snmpInterval:int,
                status:int
            >
        >,
        securityResultCode:string, 
        recordGeneratedBy:string,
        receivedMessageDetails:struct< 
            locationData:struct< 
                elevation:float, 
                heading:string, 
                latitude:float, 
                speed:float, 
                longitude:float 
            >,
            rxSource:string 
        >,
        schemaVersion: int,
        payloadType:string,
        validSignature:boolean, 
        serialId:struct<
            recordId:int,
            serialNumber:int,
            streamId:string,
            bundleSize:int,
            bundleId:int
        >,
        sanitized:boolean,
        recordGeneratedAt:string,
        recordType:string, 
        logFileName:string, 
        odeReceivedAt:string
    >,
    payload struct<
        data:struct<
            MessageFrame:struct<
                messageId:int,
                value:struct<
                    TravelerInformation:struct<
                        timeStampTravelerInformation:int,
                        packetID:string,
                        urlB:string,
                        dataFrames:struct<
                            TravelerDataFrame:struct<
                                regions:string,   -- struct type, but cast to STRING in Restructring
                                durationTime:int,
                                sspMsgRights1:int,
                                sspMsgRights2:int,
                                sspTimRights:int,
                                startYear:int,
                                sspLocationRights:int,
                                frameType:string, -- struct type, but cast to STRING in Restructring
								--struct<
        --                            unknown:string,
        --                            advisory:string,
        --                            roadSignage:string, 
        --                            commercialSignage:string
        --                        >,
                                msgId:struct<
                                    roadSignID:struct<
                                        crc:string, 
                                        viewAngle:bigint,
                                        mutcdCode:struct<
                                            warning:string
                                        >,
                                        position:struct<
                                            elevation:int, 
                                            lat:int,
                                            long:int
                                        >
                                    >
                                >,
                                startTime:int,
                                priority:int,
                                content:struct<
                                    advisory:struct<
                                        sequenceAdvisory:array<
                                            struct<
                                                item:struct<
                                                    itis:int,
													text:string  -- added in Restructring
                                                >
                                            >
                                        >
                                    >
                                >,
                                url:string
                            >
                        >,
                        msgCnt:int
                    >
                >
            >
        >,
        dataType:string
    >
)
ROW FORMAT SERDE
   'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
 STORED AS INPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
 OUTPUTFORMAT
   'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
 TBLPROPERTIES (
   'orc.compress'='Zlib'
);

