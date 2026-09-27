-- ============================================================
-- 04_data_quality_queries.sql
-- Data Quality Checks
-- ============================================================

USE ecommerce_analytics_db;


-- ============================================================
-- 1. Null Event IDs
-- ============================================================

SELECT
    COUNT(*) AS null_event_ids
FROM curated_events
WHERE event_id IS NULL;


-- ============================================================
-- 2. Null User IDs
-- ============================================================

SELECT
    COUNT(*) AS null_user_ids
FROM curated_events
WHERE user_id IS NULL;


-- ============================================================
-- 3. Null Session IDs
-- ============================================================

SELECT
    COUNT(*) AS null_session_ids
FROM curated_events
WHERE session_id IS NULL;


-- ============================================================
-- 4. Invalid Event Types
-- ============================================================

SELECT
    event_type,
    COUNT(*) AS records

FROM curated_events

WHERE event_type NOT IN
(
    'page_view',
    'product_view',
    'search',
    'add_to_cart',
    'remove_from_cart',
    'checkout_started',
    'purchase'
)

GROUP BY event_type;


-- ============================================================
-- 5. Negative Prices
-- ============================================================

SELECT
    COUNT(*) AS negative_prices
FROM curated_events
WHERE price < 0;


-- ============================================================
-- 6. Negative Quantities
-- ============================================================

SELECT
    COUNT(*) AS negative_quantities
FROM curated_events
WHERE quantity < 0;


-- ============================================================
-- 7. Purchase Events Missing Product Information
-- ============================================================

SELECT
    COUNT(*) AS invalid_purchase_products

FROM curated_events

WHERE event_type = 'purchase'

AND
(
    product_id IS NULL
    OR product_name IS NULL
);


-- ============================================================
-- 8. Purchase Events with Invalid Quantity
-- ============================================================

SELECT
    COUNT(*) AS invalid_purchase_quantities

FROM curated_events

WHERE event_type = 'purchase'

AND quantity <= 0;


-- ============================================================
-- 9. Duplicate Event IDs
-- ============================================================

SELECT
    event_id,
    COUNT(*) AS duplicate_count

FROM curated_events

GROUP BY event_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- ============================================================
-- 10. Processing Status Check
-- ============================================================

SELECT
    processing_status,
    COUNT(*) AS records

FROM curated_events

GROUP BY processing_status;


-- ============================================================
-- 11. Missing Processing Timestamp
-- ============================================================

SELECT
    COUNT(*) AS missing_processing_timestamp

FROM curated_events

WHERE processing_timestamp IS NULL;


-- ============================================================
-- 12. Negative Order Value
-- ============================================================

SELECT
    COUNT(*) AS negative_order_values

FROM curated_events

WHERE order_value < 0;


-- ============================================================
-- 13. Search Events with Unexpected Quantity
-- ============================================================

SELECT
    COUNT(*) AS invalid_search_quantity

FROM curated_events

WHERE event_type = 'search'

AND quantity <> 0;


-- ============================================================
-- 14. Overall Data Quality Summary
-- ============================================================

SELECT

    COUNT(*) AS total_records,

    COUNT_IF(event_id IS NULL) AS null_event_ids,

    COUNT_IF(user_id IS NULL) AS null_user_ids,

    COUNT_IF(session_id IS NULL) AS null_session_ids,

    COUNT_IF(price < 0) AS negative_prices,

    COUNT_IF(quantity < 0) AS negative_quantities,

    COUNT_IF(order_value < 0) AS negative_order_values

FROM curated_events;