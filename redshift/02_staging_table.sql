CREATE TABLE IF NOT EXISTS staging.staging_events
(
    event_id             VARCHAR(100),
    event_timestamp      TIMESTAMP,
    user_id              VARCHAR(100),
    session_id           VARCHAR(100),
    event_type           VARCHAR(50),

    product_id           VARCHAR(100),
    product_name         VARCHAR(255),
    category             VARCHAR(100),

    price                DECIMAL(12,2),
    quantity             INTEGER,

    device               VARCHAR(50),
    browser              VARCHAR(100),

    city                 VARCHAR(100),
    country              VARCHAR(100),

    event_date           DATE,
    event_hour           INTEGER,

    order_value          DECIMAL(12,2),
    is_purchase          BOOLEAN,

    processing_timestamp TIMESTAMP,
    processing_status    VARCHAR(30)
)
SORTKEY AUTO;

-- Verify
SELECT *
FROM staging.staging_events
LIMIT 10;