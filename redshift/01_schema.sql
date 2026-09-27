CREATE SCHEMA IF NOT EXISTS staging;

CREATE SCHEMA IF NOT EXISTS dw;

-- Verify schemas
SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN ('staging', 'dw')
ORDER BY schema_name;