-- Total events
SELECT COUNT(*) AS total_events
FROM dw.fact_clickstream;


-- Active users
SELECT COUNT(DISTINCT user_sk) AS active_users
FROM dw.fact_clickstream;


-- Purchases
SELECT COUNT(*) AS purchases
FROM dw.fact_clickstream
WHERE is_purchase = TRUE;


-- Revenue
SELECT
    ROUND(SUM(order_value), 2) AS total_revenue
FROM dw.fact_clickstream
WHERE is_purchase = TRUE;


-- Events by type
SELECT
    event_type,
    COUNT(*) AS event_count
FROM dw.fact_clickstream
GROUP BY event_type
ORDER BY event_count DESC;


-- Revenue by category
SELECT
    p.category,
    ROUND(SUM(f.order_value), 2) AS revenue
FROM dw.fact_clickstream f
JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
WHERE f.is_purchase = TRUE
GROUP BY p.category
ORDER BY revenue DESC;


-- Top products
SELECT
    p.product_name,
    p.category,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.order_value), 2) AS revenue
FROM dw.fact_clickstream f
JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
WHERE f.is_purchase = TRUE
GROUP BY
    p.product_name,
    p.category
ORDER BY revenue DESC
LIMIT 10;


-- Users by device
SELECT
    d.device,
    COUNT(DISTINCT f.user_sk) AS users
FROM dw.fact_clickstream f
JOIN dw.dim_device d
    ON f.device_sk = d.device_sk
GROUP BY d.device
ORDER BY users DESC;


-- Daily performance
SELECT
    event_date,
    total_events,
    active_users,
    purchases,
    revenue
FROM dw.v_daily_activity
ORDER BY event_date;


-- Product performance
SELECT *
FROM dw.v_product_performance
ORDER BY revenue DESC;


-- Device performance
SELECT *
FROM dw.v_device_performance
ORDER BY revenue DESC;