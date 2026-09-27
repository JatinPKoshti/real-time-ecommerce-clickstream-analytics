-- ============================================================
-- 03_views.sql
-- Reusable Athena Views
-- ============================================================

USE ecommerce_analytics_db;


-- ============================================================
-- 1. Daily Activity View
-- ============================================================

CREATE OR REPLACE VIEW v_daily_activity AS

SELECT

    event_date,

    COUNT(*) AS total_events,

    COUNT(DISTINCT user_id) AS active_users,

    COUNT(DISTINCT session_id) AS sessions,

    SUM(
        CASE
            WHEN event_type = 'purchase'
            THEN 1
            ELSE 0
        END
    ) AS purchases,

    ROUND(
        SUM(
            CASE
                WHEN event_type = 'purchase'
                THEN order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM curated_events

GROUP BY event_date;


-- ============================================================
-- 2. Product Performance View
-- ============================================================

CREATE OR REPLACE VIEW v_product_performance AS

SELECT

    product_id,

    product_name,

    category,

    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN event_type = 'product_view'
            THEN 1
            ELSE 0
        END
    ) AS product_views,

    SUM(
        CASE
            WHEN event_type = 'add_to_cart'
            THEN 1
            ELSE 0
        END
    ) AS add_to_cart,

    SUM(
        CASE
            WHEN event_type = 'checkout_started'
            THEN 1
            ELSE 0
        END
    ) AS checkout_started,

    SUM(
        CASE
            WHEN event_type = 'purchase'
            THEN 1
            ELSE 0
        END
    ) AS purchases,

    SUM(
        CASE
            WHEN event_type = 'purchase'
            THEN quantity
            ELSE 0
        END
    ) AS units_sold,

    ROUND(
        SUM(
            CASE
                WHEN event_type = 'purchase'
                THEN order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM curated_events

WHERE product_id IS NOT NULL

GROUP BY
    product_id,
    product_name,
    category;


-- ============================================================
-- 3. Device Performance View
-- ============================================================

CREATE OR REPLACE VIEW v_device_performance AS

SELECT

    device,

    COUNT(*) AS total_events,

    COUNT(DISTINCT user_id) AS active_users,

    COUNT(DISTINCT session_id) AS sessions,

    SUM(
        CASE
            WHEN event_type = 'purchase'
            THEN 1
            ELSE 0
        END
    ) AS purchases,

    ROUND(
        SUM(
            CASE
                WHEN event_type = 'purchase'
                THEN order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM curated_events

GROUP BY device;


-- ============================================================
-- 4. Hourly Activity View
-- ============================================================

CREATE OR REPLACE VIEW v_hourly_activity AS

SELECT

    event_date,

    event_hour,

    COUNT(*) AS total_events,

    COUNT(DISTINCT user_id) AS active_users,

    COUNT(DISTINCT session_id) AS sessions,

    SUM(
        CASE
            WHEN event_type = 'purchase'
            THEN 1
            ELSE 0
        END
    ) AS purchases

FROM curated_events

GROUP BY
    event_date,
    event_hour;


-- ============================================================
-- 5. City Performance View
-- ============================================================

CREATE OR REPLACE VIEW v_city_performance AS

SELECT

    city,

    country,

    COUNT(*) AS total_events,

    COUNT(DISTINCT user_id) AS active_users,

    SUM(
        CASE
            WHEN event_type = 'purchase'
            THEN 1
            ELSE 0
        END
    ) AS purchases,

    ROUND(
        SUM(
            CASE
                WHEN event_type = 'purchase'
                THEN order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM curated_events

GROUP BY
    city,
    country;


-- ============================================================
-- 6. Purchase Summary View
-- ============================================================

CREATE OR REPLACE VIEW v_purchase_summary AS

SELECT

    event_date,

    COUNT(*) AS purchase_events,

    SUM(quantity) AS units_sold,

    ROUND(
        SUM(order_value),
        2
    ) AS revenue,

    ROUND(
        AVG(order_value),
        2
    ) AS average_order_value,

    COUNT(DISTINCT user_id) AS purchasing_users

FROM curated_events

WHERE event_type = 'purchase'

GROUP BY event_date;