CREATE DATABASE IF NOT EXISTS ecommerce_analytics_db;

USE ecommerce_analytics_db;

SHOW TABLES;

DESCRIBE curated_events;

SHOW CREATE TABLE curated_events;

SELECT *
FROM curated_events
LIMIT 20;

SELECT COUNT(*) AS total_events
FROM curated_events;