-- User dimension
CREATE TABLE IF NOT EXISTS dw.dim_user
(
    user_sk      BIGINT IDENTITY(1,1),
    user_id      VARCHAR(100),
    first_seen   TIMESTAMP,
    last_seen    TIMESTAMP
)
SORTKEY AUTO;


-- Product dimension
CREATE TABLE IF NOT EXISTS dw.dim_product
(
    product_sk    BIGINT IDENTITY(1,1),
    product_id    VARCHAR(100),
    product_name  VARCHAR(255),
    category      VARCHAR(100)
)
SORTKEY AUTO;


-- Device dimension
CREATE TABLE IF NOT EXISTS dw.dim_device
(
    device_sk  BIGINT IDENTITY(1,1),
    device     VARCHAR(50),
    browser    VARCHAR(100)
)
SORTKEY AUTO;


-- Location dimension
CREATE TABLE IF NOT EXISTS dw.dim_location
(
    location_sk  BIGINT IDENTITY(1,1),
    city         VARCHAR(100),
    country      VARCHAR(100)
)
SORTKEY AUTO;


-- Fact table
CREATE TABLE IF NOT EXISTS dw.fact_clickstream
(
    event_sk                BIGINT IDENTITY(1,1),

    event_id                VARCHAR(100),
    event_timestamp         TIMESTAMP,

    user_sk                 BIGINT,
    product_sk              BIGINT,
    device_sk               BIGINT,
    location_sk             BIGINT,

    event_type              VARCHAR(50),

    price                   DECIMAL(12,2),
    quantity                INTEGER,
    order_value             DECIMAL(12,2),

    is_purchase             BOOLEAN,

    event_date              DATE,
    event_hour              INTEGER,

    processing_timestamp    TIMESTAMP,
    processing_status       VARCHAR(30)
)
SORTKEY AUTO;