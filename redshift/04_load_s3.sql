-- ============================================================
-- 04_load_s3.sql
-- Load curated Project 2 data from S3 into Redshift staging
-- ============================================================

-- IMPORTANT:
-- Replace <YOUR_ACTUAL_BUCKET> with your real Project 2 bucket.
-- Do not use YOUR_BUCKET literally.

-- Test access without loading rows:
COPY staging.staging_events
FROM 's3://<YOUR_ACTUAL_BUCKET>/curated/events/'
IAM_ROLE default
FORMAT JSON 'auto'
TIMEFORMAT 'auto'
DATEFORMAT 'auto'
NOLOAD;


