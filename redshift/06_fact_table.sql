TRUNCATE TABLE dw.fact_clickstream;

INSERT INTO dw.fact_clickstream
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

FROM staging.staging_events s

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


-- Verify
SELECT COUNT(*) AS fact_rows
FROM dw.fact_clickstream;