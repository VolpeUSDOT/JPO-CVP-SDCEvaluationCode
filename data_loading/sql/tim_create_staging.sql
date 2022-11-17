-- Create a staging table for TIM schema version 5 and earlier

DROP TABLE IF EXISTS wydot_tim_staging;

CREATE EXTERNAL TABLE IF NOT EXISTS wydot_tim_staging (
  metadata struct<
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
        validSignature:boolean,
        payloadType:string,
        serialId:struct<
                recordId:int,
                serialNumber:int,
                streamId:string,
                bundleSize:int,
                bundleId:int
        >,
    sanitized:boolean,
    securityResultCode:string,
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
                                                        regions:string,  -- struct type, but cast to STRING in Restructring
                                                        durationtime:int,
                                                        sspMsgRights1:int,
                                                        sspMsgRights2:int,
                                                        startYear:int,
                                                        msgId:struct<
                                                                roadSignID:struct<
                                                                        crc:string, -- added in Restructring
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
                                                        url:string,
                                                        sspTimRights:int,
                                                        sspLocationRights:int,
                                                        frameType:string, -- struct type, but cast to STRING in Restructring
														--struct<
              --                                                  unknown:string,          
              --                                                  advisory:string,
              --                                                  roadSignage:string,
              --                                                  commercialSignage:string 
              --                                          >,
                                                        startTime:int
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
   --"mapping.falseclosedpath" = "false",
   --"mapping.trueclosedpath" = "true",
   --"mapping.bothdirectionality" = "both",
   --"mapping.forwarddirectionality" = "forward",
   --"mapping.reversedirectionality" = "reverse",
   --"mapping.pathdescription" = "path",
   "mapping.durationtime" = "duratonTime",  -- typo in SAE J2735
   "mapping.sequenceadvisory" = "SEQUENCE",
   "mapping.timestamptravelerinformation" = "timeStamp"
)

LOCATION
	's3a://DOT-SDC-CVP-STAGING-S3-BUCKET-NAME/cv/wydot/archive/TIM/v5/';

