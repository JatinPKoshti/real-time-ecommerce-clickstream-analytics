import base64
import json
import logging
import os
import re
from datetime import datetime, timezone
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError


# ============================================================
# LOGGING
# ============================================================

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# ============================================================
# CONFIGURATION
# ============================================================

AWS_REGION = os.environ.get(
    "AWS_REGION",
    "ap-south-1",
)

PROCESSED_STREAM_NAME = os.environ.get(
    "PROCESSED_STREAM_NAME",
    "",
)

REJECTED_BUCKET = os.environ.get(
    "REJECTED_BUCKET",
    "",
)

REJECTED_PREFIX = os.environ.get(
    "REJECTED_PREFIX",
    "rejected/events/",
)


# ============================================================
# AWS CLIENTS
# ============================================================

kinesis = boto3.client(
    "kinesis",
    region_name=AWS_REGION,
)

s3 = boto3.client(
    "s3",
    region_name=AWS_REGION,
)


# ============================================================
# ALLOWED EVENT TYPES
# ============================================================

ALLOWED_EVENT_TYPES = {
    "page_view",
    "product_view",
    "search",
    "add_to_cart",
    "remove_from_cart",
    "checkout_started",
    "purchase",
}


# ============================================================
# PRODUCT EVENTS
# ============================================================

PRODUCT_EVENTS = {
    "product_view",
    "add_to_cart",
    "remove_from_cart",
    "checkout_started",
    "purchase",
}


# ============================================================
# VALIDATION
# ============================================================

def validate_event(
    event: dict[str, Any],
) -> tuple[bool, list[str]]:
    """
    Validate one e-commerce clickstream event.

    Returns:
        (True, []) for a valid event.
        (False, [errors]) for an invalid event.
    """

    errors: list[str] = []

    # --------------------------------------------------------
    # Required fields
    # --------------------------------------------------------

    required_fields = [
        "event_id",
        "event_timestamp",
        "user_id",
        "session_id",
        "event_type",
        "device",
        "browser",
        "city",
        "country",
    ]

    for field in required_fields:

        value = event.get(field)

        if value is None or value == "":
            errors.append(
                f"{field} is missing"
            )

    # --------------------------------------------------------
    # Event type
    # --------------------------------------------------------

    event_type = event.get("event_type")

    if event_type not in ALLOWED_EVENT_TYPES:

        errors.append(
            "Invalid event_type"
        )

    # --------------------------------------------------------
    # Timestamp validation
    # --------------------------------------------------------

    timestamp_value = event.get(
        "event_timestamp"
    )

    if timestamp_value:

        try:

            datetime.fromisoformat(
                timestamp_value.replace(
                    "Z",
                    "+00:00",
                )
            )

        except (ValueError, TypeError):

            errors.append(
                "Invalid event_timestamp"
            )

    # --------------------------------------------------------
    # Quantity validation
    # --------------------------------------------------------

    quantity = event.get("quantity")

    if not isinstance(quantity, int):

        errors.append(
            "quantity must be an integer"
        )

    elif quantity < 0:

        errors.append(
            "quantity cannot be negative"
        )

    # --------------------------------------------------------
    # Price validation
    # --------------------------------------------------------

    price = event.get("price")

    if price is not None:

        if not isinstance(
            price,
            (int, float),
        ):

            errors.append(
                "price must be numeric"
            )

        elif price < 0:

            errors.append(
                "price cannot be negative"
            )

    # --------------------------------------------------------
    # Product event validation
    # --------------------------------------------------------

    if event_type in PRODUCT_EVENTS:

        if not event.get("product_id"):

            errors.append(
                "product_id is required"
            )

        if not event.get("product_name"):

            errors.append(
                "product_name is required"
            )

        if not event.get("category"):

            errors.append(
                "category is required"
            )

        if price is None:

            errors.append(
                "price is required"
            )

        if not isinstance(quantity, int):

            errors.append(
                "quantity must be an integer"
            )

        elif quantity <= 0:

            errors.append(
                "quantity must be greater than zero"
            )

    # --------------------------------------------------------
    # Search event validation
    # --------------------------------------------------------

    if event_type == "search":

        if quantity != 0:

            errors.append(
                "search quantity should be 0"
            )

    # --------------------------------------------------------
    # Final result
    # --------------------------------------------------------

    return (
        len(errors) == 0,
        errors,
    )


# ============================================================
# TRANSFORMATION / ENRICHMENT
# ============================================================

def transform_event(
    event: dict[str, Any],
) -> dict[str, Any]:
    """
    Transform and enrich a valid clickstream event.
    """

    timestamp = datetime.fromisoformat(
        event["event_timestamp"].replace(
            "Z",
            "+00:00",
        )
    )

    price = event.get("price")
    quantity = event.get("quantity", 0)

    # --------------------------------------------------------
    # Calculate order value
    # --------------------------------------------------------

    if price is not None:

        order_value = round(
            float(price) * int(quantity),
            2,
        )

    else:

        order_value = 0.0

    # --------------------------------------------------------
    # Create processed event
    # --------------------------------------------------------

    processed_event = {
        **event,

        "event_date": (
            timestamp.date().isoformat()
        ),

        "event_hour": (
            timestamp.hour
        ),

        "order_value": order_value,

        "is_purchase": (
            event.get("event_type")
            == "purchase"
        ),

        "processing_timestamp": (
            datetime.now(timezone.utc)
            .isoformat()
        ),

        "processing_status": "VALID",
    }

    return processed_event


# ============================================================
# S3 REJECTED EVENT
# ============================================================

def write_rejected_event(
    event: dict[str, Any],
    errors: list[str],
) -> None:
    """
    Store invalid or duplicate events in S3.
    """

    if not REJECTED_BUCKET:

        raise ValueError(
            "REJECTED_BUCKET environment variable is not configured"
        )

    event_id = event.get(
        "event_id",
        "unknown-event",
    )

    # --------------------------------------------------------
    # Make event ID safe for an S3 object name
    # --------------------------------------------------------

    safe_event_id = re.sub(
        r"[^A-Za-z0-9_-]",
        "_",
        str(event_id),
    )

    rejection_timestamp = (
        datetime.now(timezone.utc)
        .isoformat()
    )

    rejection_record = {

        "rejection_timestamp":
            rejection_timestamp,

        "event_id":
            event_id,

        "errors":
            errors,

        "original_event":
            event,
    }

    today = datetime.now(
        timezone.utc
    ).strftime("%Y-%m-%d")

    object_key = (
        f"{REJECTED_PREFIX}"
        f"date={today}/"
        f"{safe_event_id}.json"
    )

    s3.put_object(
        Bucket=REJECTED_BUCKET,
        Key=object_key,
        Body=json.dumps(
            rejection_record,
            default=str,
            indent=2,
        ).encode("utf-8"),
        ContentType="application/json",
    )

    logger.info(
        "Rejected event stored: s3://%s/%s",
        REJECTED_BUCKET,
        object_key,
    )


# ============================================================
# SEND TO PROCESSED KINESIS
# ============================================================

def send_to_processed_stream(
    event: dict[str, Any],
) -> None:
    """
    Send one transformed event to the processed Kinesis stream.
    """

    try:

        response = kinesis.put_record(
            StreamName=PROCESSED_STREAM_NAME,

            Data=(
                json.dumps(
                    event,
                    default=str,
                )
                + "\n"
            ).encode("utf-8"),

            PartitionKey=event["user_id"],
        )

        logger.info(
            "Processed event sent | "
            "event_id=%s | "
            "event_type=%s | "
            "shard=%s",
            event.get("event_id"),
            event.get("event_type"),
            response.get("ShardId"),
        )

    except (
        ClientError,
        BotoCoreError,
    ):

        logger.exception(
            "Failed to send processed event to Kinesis"
        )

        raise


# ============================================================
# DECODE KINESIS RECORD
# ============================================================

def decode_kinesis_record(
    record: dict[str, Any],
) -> dict[str, Any]:
    """
    Decode a Kinesis Lambda record from Base64 to JSON.
    """

    encoded_data = (
        record["kinesis"]["data"]
    )

    decoded_data = (
        base64.b64decode(
            encoded_data
        )
        .decode("utf-8")
        .strip()
    )

    return json.loads(
        decoded_data
    )


# ============================================================
# LAMBDA HANDLER
# ============================================================

def lambda_handler(
    event: dict[str, Any],
    context: Any,
) -> dict[str, Any]:

    records = event.get(
        "Records",
        [],
    )

    logger.info(
        "Received %d Kinesis records",
        len(records),
    )

    # --------------------------------------------------------
    # Batch-level duplicate tracking
    #
    # Important:
    # This set exists only during one Lambda invocation.
    # It prevents duplicate event_id values appearing
    # in the same batch from being processed twice.
    # --------------------------------------------------------

    seen_event_ids: set[str] = set()

    valid_count = 0
    processed_count = 0
    rejected_count = 0
    duplicate_count = 0
    parse_error_count = 0

    batch_item_failures: list[
        dict[str, str]
    ] = []

    # ========================================================
    # PROCESS EACH RECORD
    # ========================================================

    for record_number, record in enumerate(
        records,
        start=1,
    ):

        sequence_number = (
            record["kinesis"][
                "sequenceNumber"
            ]
        )

        try:

            # ------------------------------------------------
            # Decode JSON
            # ------------------------------------------------

            clickstream_event = (
                decode_kinesis_record(
                    record
                )
            )

            event_id = clickstream_event.get(
                "event_id"
            )

            event_type = clickstream_event.get(
                "event_type"
            )

            logger.info(
                "Record %d | event_id=%s | type=%s",
                record_number,
                event_id,
                event_type,
            )

            # ------------------------------------------------
            # Duplicate detection
            # ------------------------------------------------

            if event_id in seen_event_ids:

                duplicate_count += 1

                duplicate_errors = [
                    "Duplicate event_id in current Lambda batch"
                ]

                logger.warning(
                    "Duplicate event detected | event_id=%s",
                    event_id,
                )

                write_rejected_event(
                    clickstream_event,
                    duplicate_errors,
                )

                continue

            if event_id:

                seen_event_ids.add(
                    event_id
                )

            # ------------------------------------------------
            # Validation
            # ------------------------------------------------

            is_valid, errors = (
                validate_event(
                    clickstream_event
                )
            )

            if not is_valid:

                rejected_count += 1

                logger.warning(
                    "Invalid event | "
                    "event_id=%s | "
                    "errors=%s",
                    event_id,
                    errors,
                )

                write_rejected_event(
                    clickstream_event,
                    errors,
                )

                continue

            valid_count += 1

            # ------------------------------------------------
            # Transform
            # ------------------------------------------------

            processed_event = (
                transform_event(
                    clickstream_event
                )
            )

            # ------------------------------------------------
            # Send to processed Kinesis
            # ------------------------------------------------

            send_to_processed_stream(
                processed_event
            )

            processed_count += 1

        except json.JSONDecodeError as error:

            parse_error_count += 1

            logger.exception(
                "JSON parsing failed | record=%d | error=%s",
                record_number,
                error,
            )

            # Retry the Kinesis record because
            # we couldn't determine whether the data
            # should be accepted or rejected.
            batch_item_failures.append(
                {
                    "itemIdentifier":
                        sequence_number
                }
            )

        except (
            ClientError,
            BotoCoreError,
        ) as error:

            logger.exception(
                "AWS error while processing record=%d | error=%s",
                record_number,
                error,
            )

            # Return this Kinesis record as failed.
            # With ReportBatchItemFailures enabled,
            # Lambda will retry the failed record.
            batch_item_failures.append(
                {
                    "itemIdentifier":
                        sequence_number
                }
            )

        except Exception as error:

            logger.exception(
                "Unexpected error | record=%d | error=%s",
                record_number,
                error,
            )

            batch_item_failures.append(
                {
                    "itemIdentifier":
                        sequence_number
                }
            )

    # ========================================================
    # BATCH SUMMARY
    # ========================================================

    logger.info(
        "BATCH SUMMARY | "
        "total=%d | "
        "valid=%d | "
        "processed=%d | "
        "rejected=%d | "
        "duplicates=%d | "
        "parse_errors=%d | "
        "retry=%d",

        len(records),
        valid_count,
        processed_count,
        rejected_count,
        duplicate_count,
        parse_error_count,
        len(batch_item_failures),
    )

    # ========================================================
    # LAMBDA RESPONSE
    # ========================================================

    return {
        "batchItemFailures":
            batch_item_failures
    }