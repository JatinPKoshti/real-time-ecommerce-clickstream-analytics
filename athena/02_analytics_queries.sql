-- ============================================================
-- 02_analytics_queries.sql
-- Real-Time E-Commerce Clickstream Analytics
-- ============================================================

USE ecommerce_analytics_db;

-- 1. Total Events
SELECT COUNT(*) AS total_events
FROM curated_events;


-- 2. Events by Event Type
SELECT
    event_type,
    COUNT(*) AS event_count
FROM curated_events
GROUP BY event_type
ORDER BY event_count DESC;


-- 3. Active Users
SELECT
    COUNT(DISTINCT user_id) AS active_users
FROM curated_events;


-- 4. Unique Sessions
SELECT
    COUNT(DISTINCT session_id) AS unique_sessions
FROM curated_events;


-- 5. Total Purchases
SELECT
    COUNT(*) AS purchase_events
FROM curated_events
WHERE event_type = 'purchase';


-- 6. Total Revenue
SELECT
    ROUND(SUM(order_value), 2) AS total_revenue
FROM curated_events
WHERE event_type = 'purchase';


-- 7. Revenue by Product
SELECT
    product_id,
    product_name,
    ROUND(SUM(order_value), 2) AS revenue,
    SUM(quantity) AS units_sold
FROM curated_events
WHERE event_type = 'purchase'
GROUP BY product_id, product_name
ORDER BY revenue DESC;


-- 8. Revenue by Category
SELECT
    category,
    ROUND(SUM(order_value), 2) AS revenue,
    COUNT(*) AS purchase_events
FROM curated_events
WHERE event_type = 'purchase'
GROUP BY category
ORDER BY revenue DESC;


-- 9. Product Engagement
SELECT
    product_id,
    product_name,

    COUNT(*) AS total_product_events,

    SUM(
        CASE
            WHEN event_type = 'product_view' THEN 1
            ELSE 0
        END
    ) AS product_views,

    SUM(
        CASE
            WHEN event_type = 'add_to_cart' THEN 1
            ELSE 0
        END
    ) AS add_to_cart,

    SUM(
        CASE
            WHEN event_type = 'remove_from_cart' THEN 1
            ELSE 0
        END
    ) AS remove_from_cart,

    SUM(
        CASE
            WHEN event_type = 'checkout_started' THEN 1
            ELSE 0
        END
    ) AS checkout_started,

    SUM(
        CASE
            WHEN event_type = 'purchase' THEN 1
            ELSE 0
        END
    ) AS purchases

FROM curated_events

WHERE product_id IS NOT NULL

GROUP BY
    product_id,
    product_name

ORDER BY total_product_events DESC;


-- 10. Users by Device
SELECT
    device,
    COUNT(*) AS events,
    COUNT(DISTINCT user_id) AS users
FROM curated_events
GROUP BY device
ORDER BY users DESC;


-- 11. Events by Browser
SELECT
    browser,
    COUNT(*) AS events,
    COUNT(DISTINCT user_id) AS users
FROM curated_events
GROUP BY browser
ORDER BY events DESC;


-- 12. Events by City
SELECT
    city,
    COUNT(*) AS events,
    COUNT(DISTINCT user_id) AS users
FROM curated_events
GROUP BY city
ORDER BY events DESC;


-- 13. Hourly Activity
SELECT
    event_date,
    event_hour,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS active_users
FROM curated_events
GROUP BY
    event_date,
    event_hour
ORDER BY
    event_date,
    event_hour;


-- 14. Daily Activity
SELECT
    event_date,

    COUNT(*) AS total_events,

    COUNT(DISTINCT user_id) AS active_users,

    COUNT(DISTINCT session_id) AS sessions,

    SUM(
        CASE
            WHEN event_type = 'purchase' THEN 1
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

GROUP BY event_date

ORDER BY event_date;


-- 15. Revenue Trend
SELECT
    event_date,
    ROUND(SUM(order_value), 2) AS revenue
FROM curated_events
WHERE event_type = 'purchase'
GROUP BY event_date
ORDER BY event_date;


-- 16. Conversion Funnel
SELECT
    SUM(
        CASE
            WHEN event_type = 'page_view' THEN 1
            ELSE 0
        END
    ) AS page_views,

    SUM(
        CASE
            WHEN event_type = 'product_view' THEN 1
            ELSE 0
        END
    ) AS product_views,

    SUM(
        CASE
            WHEN event_type = 'add_to_cart' THEN 1
            ELSE 0
        END
    ) AS add_to_cart,

    SUM(
        CASE
            WHEN event_type = 'checkout_started' THEN 1
            ELSE 0
        END
    ) AS checkout_started,

    SUM(
        CASE
            WHEN event_type = 'purchase' THEN 1
            ELSE 0
        END
    ) AS purchases

FROM curated_events;


-- 17. User Purchase Summary
SELECT
    user_id,

    COUNT(*) AS total_events,

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
    ) AS total_spend

FROM curated_events

GROUP BY user_id

ORDER BY total_spend DESC;


-- 18. Session Activity
SELECT
    session_id,

    user_id,

    COUNT(*) AS events,

    MIN(event_timestamp) AS session_start,

    MAX(event_timestamp) AS session_end,

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
    session_id,
    user_id

ORDER BY session_start;


-- 19. Latest 100 Events
SELECT *
FROM curated_events
ORDER BY event_timestamp DESC
LIMIT 100;


-- 20. Average Order Value
SELECT
    ROUND(AVG(order_value), 2) AS average_order_value
FROM curated_events
WHERE event_type = 'purchase';


-- 21. Units Sold by Product
SELECT
    product_id,
    product_name,
    SUM(quantity) AS units_sold
FROM curated_events
WHERE event_type = 'purchase'
GROUP BY
    product_id,
    product_name
ORDER BY units_sold DESC;


-- 22. Events by Country
SELECT
    country,
    COUNT(*) AS events,
    COUNT(DISTINCT user_id) AS users
FROM curated_events
GROUP BY country
ORDER BY events DESC;


-- 23. Purchases by Device
SELECT
    device,

    COUNT(*) AS purchases,

    ROUND(SUM(order_value), 2) AS revenue,

    ROUND(AVG(order_value), 2) AS average_order_value

FROM curated_events

WHERE event_type = 'purchase'

GROUP BY device

ORDER BY revenue DESC;


-- 24. Add-to-Cart vs Purchase by Category
SELECT
    category,

    SUM(
        CASE
            WHEN event_type = 'add_to_cart'
            THEN 1
            ELSE 0
        END
    ) AS add_to_cart,

    SUM(
        CASE
            WHEN event_type = 'purchase'
            THEN 1
            ELSE 0
        END
    ) AS purchases

FROM curated_events

WHERE category IS NOT NULL

GROUP BY category

ORDER BY add_to_cart DESC;


-- 25. Funnel Conversion Rates
WITH funnel AS
(
    SELECT

        SUM(
            CASE
                WHEN event_type = 'page_view'
                THEN 1
                ELSE 0
            END
        ) AS page_views,

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
        ) AS purchases

    FROM curated_events
)

SELECT

    page_views,

    product_views,

    add_to_cart,

    checkout_started,

    purchases,

    ROUND(
        100.0 * product_views
        / NULLIF(page_views, 0),
        2
    ) AS view_rate_pct,

    ROUND(
        100.0 * add_to_cart
        / NULLIF(product_views, 0),
        2
    ) AS cart_rate_pct,

    ROUND(
        100.0 * checkout_started
        / NULLIF(add_to_cart, 0),
        2
    ) AS checkout_rate_pct,

    ROUND(
        100.0 * purchases
        / NULLIF(checkout_started, 0),
        2
    ) AS purchase_rate_pct

FROM funnel;


-- 26. Processing Status
SELECT
    processing_status,
    COUNT(*) AS records
FROM curated_events
GROUP BY processing_status
ORDER BY records DESC;


-- 27. Processing Delay
SELECT

    COUNT(*) AS records,

    ROUND(
        AVG(
            date_diff(
                'second',
                CAST(event_timestamp AS timestamp),
                CAST(processing_timestamp AS timestamp)
            )
        ),
        2
    ) AS avg_processing_delay_seconds,

    MAX(
        date_diff(
            'second',
            CAST(event_timestamp AS timestamp),
            CAST(processing_timestamp AS timestamp)
        )
    ) AS max_processing_delay_seconds

FROM curated_events;


-- 28. Daily Event-Type Distribution
SELECT
    event_date,
    event_type,
    COUNT(*) AS event_count
FROM curated_events
GROUP BY
    event_date,
    event_type
ORDER BY
    event_date,
    event_count DESC;


-- 29. Top 10 Products by Units Sold
SELECT
    product_id,
    product_name,
    SUM(quantity) AS units_sold
FROM curated_events
WHERE event_type = 'purchase'
GROUP BY
    product_id,
    product_name
ORDER BY units_sold DESC
LIMIT 10;


-- 30. Top 10 Products by Revenue
SELECT
    product_id,
    product_name,
    ROUND(SUM(order_value), 2) AS revenue
FROM curated_events
WHERE event_type = 'purchase'
GROUP BY
    product_id,
    product_name
ORDER BY revenue DESC
LIMIT 10;