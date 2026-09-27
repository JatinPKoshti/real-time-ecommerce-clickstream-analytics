# Real-Time E-Commerce Clickstream Analytics Platform

> Near-real-time end-to-end Data Engineering platform for processing, validating, transforming, warehousing, querying, monitoring, and visualizing e-commerce clickstream data on AWS.

## Project Overview

This project simulates an e-commerce website that continuously generates clickstream events such as page views, product views, searches, add-to-cart, checkout, and purchases.

The platform uses Amazon Kinesis for streaming ingestion, AWS Lambda for validation and transformation, Amazon Data Firehose for S3 delivery, Amazon S3 for data lake storage, AWS Glue for cataloging, Amazon Athena for SQL analytics, Amazon Redshift Serverless for data warehousing, Amazon QuickSight for BI dashboards, and CloudWatch/SNS for monitoring and alerts.

## Architecture

```text
Python Clickstream Producer
          |
          v
Amazon Kinesis RAW
ecommerce-clickstream-raw
          |
          v
AWS Lambda Processor
ecommerce-kinesis-stream-processor
          |
          +------------------> S3 rejected/events/
          |
          v
Amazon Kinesis PROCESSED
ecommerce-clickstream-processed
          |
          v
Amazon Data Firehose
          |
          v
Amazon S3
raw/events/        curated/events/
                         |
             +-----------+-----------+
             |                       |
             v                       v
        AWS Glue Catalog        Amazon Redshift
             |                  ecommerce_dw
             v                       |
        Amazon Athena          staging.staging_events
             |                       |
             |                  dw dimensions
             |                       |
             |                  fact_clickstream
             |                       |
             +-----------+-----------+
                         |
                         v
                    QuickSight

CloudWatch -> Monitoring and Alarms -> SNS
```

The project is described as **near-real-time** because buffering, delivery, query execution, and dashboard refresh introduce latency.

## AWS Services

| Service | Purpose |
|---|---|
| Amazon S3 | Raw, curated, rejected and Athena result storage |
| Amazon Kinesis Data Streams | Streaming ingestion and processed event transport |
| AWS Lambda | Event validation, transformation, routing and batch-level duplicate protection |
| Amazon Data Firehose | Delivery from Kinesis to S3 |
| AWS Glue | Crawler and Data Catalog |
| Amazon Athena | SQL analytics over curated S3 data |
| Amazon Redshift Serverless | Analytical data warehouse |
| Amazon QuickSight | BI dashboard |
| Amazon CloudWatch | Monitoring and alarms |
| Amazon SNS | Alert notifications |

## Main AWS Resource Names

### Region

```text
ap-south-1
```

### Kinesis

```text
ecommerce-clickstream-raw
ecommerce-clickstream-processed
```

### Lambda

```text
ecommerce-kinesis-stream-processor
```

### Firehose

```text
ecommerce-raw-to-s3
ecommerce-processed-to-s3
```

### Glue

```text
Database: ecommerce_analytics_db
Crawler: ecommerce-curated-events-crawler
Table: curated_events
```

### Athena

```text
Workgroup: ecommerce-analytics
```

### QuickSight

```text
Real-Time E-Commerce Clickstream Dashboard
Real-Time E-Commerce Redshift Dashboard
```

### CloudWatch

```text
Dashboard: ecommerce-clickstream-monitoring
Alarm: ecommerce-lambda-errors
Alarm: ecommerce-kinesis-consumer-lag
```

### SNS

```text
Topic: ecommerce-clickstream-alerts
```

### Redshift Serverless

```text
Namespace: ecommerce-redshift-ns
Workgroup: ecommerce-redshift-wg
Database: ecommerce_dw
IAM role: ecommerce-redshift-s3-role
```

## S3 Structure

```text
s3://<YOUR_PROJECT_2_BUCKET>/
|
├── raw/
│   └── events/
|
├── curated/
│   └── events/
|
├── rejected/
│   └── events/
|
├── athena-results/
|
└── scripts/
```

The exact bucket name is intentionally represented by a placeholder in this public README.

## Event Schema

Core event fields:

```text
event_id
event_timestamp
user_id
session_id
event_type
product_id
product_name
category
price
quantity
device
browser
city
country
```

Lambda adds:

```text
event_date
event_hour
order_value
is_purchase
processing_timestamp
processing_status
```

Supported event types:

```text
page_view
product_view
search
add_to_cart
remove_from_cart
checkout_started
purchase
```

## Python Producer

Source:

```text
producer/clickstream_producer.py
```

The producer creates synthetic events and sends them to the RAW Kinesis stream using `user_id` as the partition key.

Example:

```bash
python producer/clickstream_producer.py --aws-test
python producer/clickstream_producer.py --test 10
python producer/clickstream_producer.py --stream
```

Use `Ctrl+C` to stop continuous streaming.

## Lambda Processing

Source:

```text
lambda/ecommerce_stream_processor.py
```

Processing flow:

```text
Kinesis RAW
   |
Decode
   |
Validate
   |
Duplicate check within batch
   |
   +---- invalid --> S3 rejected/events/
   |
Transform
   |
Kinesis PROCESSED
```

Validation includes required fields, allowed event types, timestamp, price, quantity, and event-specific rules.

## S3 + Firehose

```text
ecommerce-raw-to-s3
    -> s3://<YOUR_PROJECT_2_BUCKET>/raw/events/

ecommerce-processed-to-s3
    -> s3://<YOUR_PROJECT_2_BUCKET>/curated/events/
```

Invalid events are written to:

```text
s3://<YOUR_PROJECT_2_BUCKET>/rejected/events/
```

## Glue + Athena

Glue:

```text
Database: ecommerce_analytics_db
Crawler: ecommerce-curated-events-crawler
Table: curated_events
```

Athena:

```text
Workgroup: ecommerce-analytics
Results: s3://<YOUR_PROJECT_2_BUCKET>/athena-results/
```

Athena analytics include:

- Total events
- Event counts by type
- Active users
- Sessions
- Purchases
- Revenue
- Revenue by product/category
- Product engagement
- Device/browser analysis
- City/country analysis
- Hourly and daily activity
- Conversion funnel
- User and session summaries
- Data-quality checks

SQL files:

```text
athena/
├── 01_database_setup.sql
├── 02_analytics_queries.sql
├── 03_views.sql
└── 04_data_quality_queries.sql
```

## Redshift Data Warehouse

Redshift is used as the warehouse layer for structured analytical queries.

### Staging

```text
staging.staging_events
```

### Dimensions

```text
dw.dim_user
dw.dim_product
dw.dim_device
dw.dim_location
```

### Fact

```text
dw.fact_clickstream
```

### Reporting Views

```text
dw.v_daily_activity
dw.v_product_performance
dw.v_device_performance
dw.v_hourly_activity
dw.v_city_performance
dw.v_purchase_summary
```

### Redshift Flow

```text
S3 curated/events/
       |
       v
COPY
       |
       v
staging.staging_events
       |
       v
Deduplication with ROW_NUMBER()
       |
       v
Dimension tables
       |
       v
fact_clickstream
       |
       v
MERGE for incremental processing
       |
       v
Analytics views
```

The incremental pattern uses `event_id` as the event identifier and `MERGE` to insert new events or update existing events.

## QuickSight

Recommended Redshift dashboard content:

### KPI cards

```text
Total Events
Active Users
Purchases
Revenue
```

### Visuals

```text
Daily Revenue Trend
Daily Event Activity
Top Products by Revenue
Revenue by Category
Users by Device
Hourly Clickstream Activity
Revenue by City
Purchase Summary
```

## Monitoring

CloudWatch tracks:

```text
Kinesis:
IncomingRecords
PutRecord.Success
WriteProvisionedThroughputExceeded
GetRecords.IteratorAgeMilliseconds

Lambda:
Invocations
Errors
Throttles
Duration

Firehose:
IncomingRecords
IncomingBytes
DeliveryToS3.Success
DeliveryToS3.Records
```

Alarms:

```text
ecommerce-lambda-errors
ecommerce-kinesis-consumer-lag
```

SNS topic:

```text
ecommerce-clickstream-alerts
```

## Testing

The pipeline was tested across the main processing stages.

Example producer test:

```text
Events generated: 10
Successful records: 10
Failed records: 0
```

Example Lambda processing result:

```text
Records received: 7
Valid: 7
Processed: 7
Rejected: 0
Duplicates: 0
Parse errors: 0
Retry: 0
```

Validation also covers:

```text
Staging row counts
Fact row counts
Duplicate event IDs
Dimension relationships
Purchases
Revenue
Analytics views
MERGE behaviour
```

## Repository Structure

```text
real-time-ecommerce-clickstream-analytics/
|
├── README.md
├── .gitignore
|
├── producer/
│   └── clickstream_producer.py
|
├── lambda/
│   ├── ecommerce_stream_processor.py
│   └── README.md
|
├── athena/
│   ├── README.md
│   ├── 01_database_setup.sql
│   ├── 02_analytics_queries.sql
│   ├── 03_views.sql
│   └── 04_data_quality_queries.sql
|
├── redshift/
│   ├── README.md
│   ├── 01_schema.sql
│   ├── 02_staging_table.sql
│   ├── 03_warehouse_tables.sql
│   ├── 04_load_s3.sql
│   ├── 05_dimensions.sql
│   ├── 06_fact_table.sql
│   ├── 07_incremental_merge.sql
│   ├── 08_analytics_views.sql
│   └── 09_analytics_queries.sql
|
├── config/
│   ├── README.md
│   ├── aws-resources.md
│   ├── project-config.example.json
│   └── lambda-environment.example.txt
|
├── data/
│   └── sample/
│       └── sample_clickstream.json
|
├── test/
│   └── test_event_validation.py
|
└── docs/
    ├── architecture.md
    ├── deployment.md
    ├── testing.md
    └── screenshots/
```
