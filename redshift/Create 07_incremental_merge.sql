-- Deduplicate staging events by event_id

DROP TABLE IF EXISTS temp_events_dedup;

CREATE TEMP TABLE temp_events_dedup AS

SELECT *
FROM
(
    SELECT
        s.*,

        ROW_NUMBER() OVER
        (
            PARTITION BY s.event_id
            ORDER BY s.processing_timestamp DESC
        ) AS rn

    FROM staging.staging_events s

    WHERE s.event_id IS NOT NULL
)
WHERE rn = 1;


-- Build fact source with dimension keys
DROP TABLE IF EXISTS temp_fact_source;

CREATE TEMP TABLE temp_fact_source AS

SELECT
    s.event_id,
    s.event_timestamp,

    u.user_sk,
    p.product_sk,
    d.device_sk,
    l.location_sk,

    s.event_type,
    s.price,
    s.quantity,
    s.order_value,
    s.is_purchase,

    s.event_date,
    s.event_hour,

    s.processing_timestamp,
    s.processing_status

FROM temp_events_dedup s

LEFT JOIN dw.dim_user u
    ON s.user_id = u.user_id

LEFT JOIN dw.dim_product p
    ON s.product_id = p.product_id

LEFT JOIN dw.dim_device d
    ON s.device = d.device
   AND s.browser = d.browser

LEFT JOIN dw.dim_location l
    ON s.city = l.city
   AND s.country = l.country;


-- Incremental MERGE
MERGE INTO dw.fact_clickstream AS target

USING temp_fact_source AS source

ON target.event_id = source.event_id

WHEN MATCHED THEN

UPDATE SET
    event_timestamp      = source.event_timestamp,
    user_sk               = source.user_sk,
    product_sk            = source.product_sk,
    device_sk             = source.device_sk,
    location_sk           = source.location_sk,
    event_type            = source.event_type,
    price                 = source.price,
    quantity              = source.quantity,
    order_value           = source.order_value,
    is_purchase           = source.is_purchase,
    event_date            = source.event_date,
    event_hour            = source.event_hour,
    processing_timestamp  = source.processing_timestamp,
    processing_status     = source.processing_status

WHEN NOT MATCHED THEN

INSERT
(
    event_id,
    event_timestamp,
    user_sk,
    product_sk,
    device_sk,
    location_sk,
    event_type,
    price,
    quantity,
    order_value,
    is_purchase,
    event_date,
    event_hour,
    processing_timestamp,
    processing_status
)

VALUES
(
    source.event_id,
    source.event_timestamp,
    source.user_sk,
    source.product_sk,
    source.device_sk,
    source.location_sk,
    source.event_type,
    source.price,
    source.quantity,
    source.order_value,
    source.is_purchase,
    source.event_date,
    source.event_hour,
    source.processing_timestamp,
    source.processing_status
);


-- Duplicate check
SELECT
    event_id,
    COUNT(*) AS duplicate_count
FROM dw.fact_clickstream
GROUP BY event_id
HAVING COUNT(*) > 1;