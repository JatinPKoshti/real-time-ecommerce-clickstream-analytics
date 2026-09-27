-- Daily activity
CREATE OR REPLACE VIEW dw.v_daily_activity AS
SELECT
    event_date,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_sk) AS active_users,

    SUM(
        CASE
            WHEN is_purchase = TRUE THEN 1
            ELSE 0
        END
    ) AS purchases,

    ROUND(
        SUM(
            CASE
                WHEN is_purchase = TRUE
                THEN order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM dw.fact_clickstream

GROUP BY event_date;


-- Product performance
CREATE OR REPLACE VIEW dw.v_product_performance AS
SELECT
    p.product_id,
    p.product_name,
    p.category,

    COUNT(f.event_sk) AS total_events,

    SUM(
        CASE
            WHEN f.event_type = 'product_view'
            THEN 1 ELSE 0
        END
    ) AS product_views,

    SUM(
        CASE
            WHEN f.event_type = 'add_to_cart'
            THEN 1 ELSE 0
        END
    ) AS add_to_cart,

    SUM(
        CASE
            WHEN f.is_purchase = TRUE
            THEN 1 ELSE 0
        END
    ) AS purchases,

    SUM(
        CASE
            WHEN f.is_purchase = TRUE
            THEN f.quantity ELSE 0
        END
    ) AS units_sold,

    ROUND(
        SUM(
            CASE
                WHEN f.is_purchase = TRUE
                THEN f.order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM dw.fact_clickstream f

LEFT JOIN dw.dim_product p
    ON f.product_sk = p.product_sk

GROUP BY
    p.product_id,
    p.product_name,
    p.category;


-- Device performance
CREATE OR REPLACE VIEW dw.v_device_performance AS
SELECT
    d.device,
    d.browser,

    COUNT(f.event_sk) AS total_events,

    COUNT(DISTINCT f.user_sk) AS active_users,

    SUM(
        CASE
            WHEN f.is_purchase = TRUE
            THEN 1 ELSE 0
        END
    ) AS purchases,

    ROUND(
        SUM(
            CASE
                WHEN f.is_purchase = TRUE
                THEN f.order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM dw.fact_clickstream f

LEFT JOIN dw.dim_device d
    ON f.device_sk = d.device_sk

GROUP BY
    d.device,
    d.browser;


-- Hourly activity
CREATE OR REPLACE VIEW dw.v_hourly_activity AS
SELECT
    event_date,
    event_hour,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_sk) AS active_users,

    SUM(
        CASE
            WHEN is_purchase = TRUE
            THEN 1 ELSE 0
        END
    ) AS purchases,

    ROUND(
        SUM(
            CASE
                WHEN is_purchase = TRUE
                THEN order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM dw.fact_clickstream

GROUP BY
    event_date,
    event_hour;


-- City performance
CREATE OR REPLACE VIEW dw.v_city_performance AS
SELECT
    l.city,
    l.country,

    COUNT(f.event_sk) AS total_events,

    COUNT(DISTINCT f.user_sk) AS active_users,

    SUM(
        CASE
            WHEN f.is_purchase = TRUE
            THEN 1 ELSE 0
        END
    ) AS purchases,

    ROUND(
        SUM(
            CASE
                WHEN f.is_purchase = TRUE
                THEN f.order_value
                ELSE 0
            END
        ),
        2
    ) AS revenue

FROM dw.fact_clickstream f

LEFT JOIN dw.dim_location l
    ON f.location_sk = l.location_sk

GROUP BY
    l.city,
    l.country;


-- Purchase summary
CREATE OR REPLACE VIEW dw.v_purchase_summary AS
SELECT
    event_date,
    COUNT(*) AS purchase_events,
    SUM(quantity) AS units_sold,
    ROUND(SUM(order_value), 2) AS revenue,
    ROUND(AVG(order_value), 2) AS average_order_value,
    COUNT(DISTINCT user_sk) AS purchasing_users

FROM dw.fact_clickstream

WHERE is_purchase = TRUE

GROUP BY event_date;