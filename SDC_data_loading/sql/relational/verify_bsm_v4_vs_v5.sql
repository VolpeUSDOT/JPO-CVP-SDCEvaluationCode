-- simple sql script to do test whether schema 5 and 4 data is available in wydot_bsm_core
-- with metadataschemaversion 5 you should get results; with 4 not; if you disable the AND statements, 4 should return
-- values as well.

SELECT core.metadataReceivedMessageDetailsLocationDataSpeed, part.classDetailsRole, *
FROM wydot_bsm_core core JOIN wydot_bsm_partii part
ON (core.bsmid == part.bsmid)
WHERE core.metadataschemaversion = 5
AND part.classDetailsRole IS NOT NULL
AND core.metadataReceivedMessageDetailsLocationDataSpeed != 0
LIMIT 10;

