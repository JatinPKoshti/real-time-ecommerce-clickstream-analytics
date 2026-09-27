-- User dimension
TRUNCATE TABLE dw.dim_user;

INSERT INTO dw.dim_user
(
    user_id,
    first_seen,
    last_seen
)
SELECT
    user_id,
    MIN(event_timestamp),
    MAX(event_timestamp)
FROM staging.staging_events
WHERE user_id IS NOT NULL
GROUP BY user_id;


-- Product dimension
TRUNCATE TABLE dw.dim_product;

INSERT INTO dw.dim_product
(
    product_id,
    product_name,
    category
)
SELECT
    product_id,
    MAX(product_name),
    MAX(category)
FROM staging.staging_events
WHERE product_id IS NOT NULL
GROUP BY product_id;


-- Device dimension
TRUNCATE TABLE dw.dim_device;

INSERT INTO dw.dim_device
(
    device,
    browser
)
SELECT DISTINCT
    device,
    browser
FROM staging.staging_events
WHERE device IS NOT NULL;


-- Location dimension
TRUNCATE TABLE dw.dim_location;

INSERT INTO dw.dim_location
(
    city,
    country
)
SELECT DISTINCT
    city,
    country
FROM staging.staging_events
WHERE city IS NOT NULL
   OR country IS NOT NULL;


-- Verification
SELECT COUNT(*) AS users
FROM dw.dim_user;

SELECT COUNT(*) AS products
FROM dw.dim_product;

SELECT COUNT(*) AS devices
FROM dw.dim_device;

SELECT COUNT(*) AS locations
FROM dw.dim_location;