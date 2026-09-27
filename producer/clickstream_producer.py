import json
import random
import sys
import time
import uuid
from datetime import datetime, timezone
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError


# ============================================================
# AWS / KINESIS CONFIGURATION
# ============================================================

AWS_REGION = "ap-south-1"
KINESIS_STREAM_NAME = ""


# Create Kinesis client.
# Boto3 will use your configured AWS credentials.
kinesis = boto3.client(
    "kinesis",
    region_name=AWS_REGION,
)


# ============================================================
# CLICKSTREAM EVENT CONFIGURATION
# ============================================================

EVENT_TYPES = [
    "page_view",
    "product_view",
    "search",
    "add_to_cart",
    "remove_from_cart",
    "checkout_started",
    "purchase",
]


PRODUCTS = [
    {
        "product_id": "P1001",
        "product_name": "Wireless Headphones",
        "category": "Electronics",
        "price": 2499.00,
    },
    {
        "product_id": "P1002",
        "product_name": "Smart Watch",
        "category": "Electronics",
        "price": 4999.00,
    },
    {
        "product_id": "P1003",
        "product_name": "Running Shoes",
        "category": "Footwear",
        "price": 3299.00,
    },
    {
        "product_id": "P1004",
        "product_name": "Backpack",
        "category": "Fashion",
        "price": 1599.00,
    },
    {
        "product_id": "P1005",
        "product_name": "Coffee Maker",
        "category": "Home Appliances",
        "price": 4599.00,
    },
    {
        "product_id": "P1006",
        "product_name": "Bluetooth Speaker",
        "category": "Electronics",
        "price": 1999.00,
    },
    {
        "product_id": "P1007",
        "product_name": "Cotton T-Shirt",
        "category": "Fashion",
        "price": 799.00,
    },
    {
        "product_id": "P1008",
        "product_name": "Office Chair",
        "category": "Furniture",
        "price": 6999.00,
    },
]


DEVICES = [
    "mobile",
    "desktop",
    "tablet",
]


BROWSERS = [
    "Chrome",
    "Edge",
    "Firefox",
    "Safari",
]


CITIES = [
    "Ahmedabad",
    "Mumbai",
    "Pune",
    "Bengaluru",
    "Delhi",
    "Hyderabad",
    "Chennai",
    "Kolkata",
]


COUNTRY = "India"


# ============================================================
# EVENT GENERATION
# ============================================================

def generate_event() -> dict[str, Any]:
    """
    Generate one realistic e-commerce clickstream event.

    Returns:
        Dictionary containing the complete event.
    """

    event_type = random.choice(EVENT_TYPES)
    product = random.choice(PRODUCTS)

    # Search events don't necessarily correspond
    # to a specific product.
    if event_type == "search":
        product_id = None
        product_name = None
        category = None
        price = None
        quantity = 0

    else:
        product_id = product["product_id"]
        product_name = product["product_name"]
        category = product["category"]
        price = product["price"]
        quantity = random.randint(1, 3)

    event: dict[str, Any] = {
        "event_id": str(uuid.uuid4()),
        "event_timestamp": datetime.now(timezone.utc).isoformat(),
        "user_id": f"U{random.randint(10000, 99999)}",
        "session_id": f"S{random.randint(100000, 999999)}",
        "event_type": event_type,
        "product_id": product_id,
        "product_name": product_name,
        "category": category,
        "price": price,
        "quantity": quantity,
        "device": random.choice(DEVICES),
        "browser": random.choice(BROWSERS),
        "city": random.choice(CITIES),
        "country": COUNTRY,
    }

    return event


# ============================================================
# EVENT VALIDATION
# ============================================================

def validate_event(
    event: dict[str, Any],
) -> tuple[bool, list[str]]:
    """
    Validate a clickstream event.

    Returns:
        (True, []) for a valid event
        (False, [error messages]) for an invalid event
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
            errors.append(f"{field} is missing")

    # --------------------------------------------------------
    # Event type
    # --------------------------------------------------------

    if event.get("event_type") not in EVENT_TYPES:
        errors.append("Invalid event_type")

    # --------------------------------------------------------
    # Quantity
    # --------------------------------------------------------

    quantity = event.get("quantity")

    if not isinstance(quantity, int):
        errors.append("quantity must be an integer")

    elif quantity < 0:
        errors.append("quantity cannot be negative")

    # --------------------------------------------------------
    # Price
    # --------------------------------------------------------

    price = event.get("price")

    if price is not None:

        if not isinstance(price, (int, float)):
            errors.append("price must be numeric")

        elif price < 0:
            errors.append("price cannot be negative")

    # --------------------------------------------------------
    # Product event validation
    # --------------------------------------------------------

    product_events = {
        "product_view",
        "add_to_cart",
        "remove_from_cart",
        "checkout_started",
        "purchase",
    }

    if event.get("event_type") in product_events:

        if not event.get("product_id"):
            errors.append(
                "product_id is required for product events"
            )

        if not event.get("product_name"):
            errors.append(
                "product_name is required for product events"
            )

        if not event.get("category"):
            errors.append(
                "category is required for product events"
            )

        if event.get("price") is None:
            errors.append(
                "price is required for product events"
            )

        if not isinstance(quantity, int):
            errors.append(
                "quantity must be an integer for product events"
            )

        elif quantity <= 0:
            errors.append(
                "quantity must be greater than zero for product events"
            )

    # --------------------------------------------------------
    # Search event validation
    # --------------------------------------------------------

    if event.get("event_type") == "search":

        if quantity != 0:
            errors.append(
                "search quantity should be 0"
            )

    # --------------------------------------------------------
    # Final result
    # --------------------------------------------------------

    return len(errors) == 0, errors


# ============================================================
# SEND EVENT TO KINESIS
# ============================================================

def send_to_kinesis(
    event: dict[str, Any],
) -> dict[str, Any]:
    """
    Send one event to Amazon Kinesis Data Streams.

    The user_id is used as the partition key so that
    events are consistently routed according to user.
    """

    response = kinesis.put_record(
        StreamName=KINESIS_STREAM_NAME,
        Data=(
            json.dumps(event) + "\n"
        ).encode("utf-8"),
        PartitionKey=event["user_id"],
    )

    return response


# ============================================================
# TEST MODE
# ============================================================

def test_kinesis(
    count: int = 10,
    delay_seconds: float = 1.0,
) -> None:
    """
    Send a limited number of events to Kinesis.

    Default:
        10 events
    """

    successful = 0
    failed = 0
    rejected = 0

    print("=" * 80)
    print("KINESIS CLICKSTREAM TEST")
    print("=" * 80)
    print(f"Region      : {AWS_REGION}")
    print(f"Stream      : {KINESIS_STREAM_NAME}")
    print(f"Event count : {count}")
    print("=" * 80)

    for event_number in range(1, count + 1):

        event = generate_event()

        # Validate before sending.
        is_valid, errors = validate_event(event)

        if not is_valid:

            rejected += 1

            print(
                f"Event {event_number} "
                f"REJECTED LOCALLY | "
                f"{errors}"
            )

            continue

        try:

            response = send_to_kinesis(event)

            successful += 1

            print(
                f"Event {event_number:03d} SENT | "
                f"event_id={event['event_id']} | "
                f"type={event['event_type']} | "
                f"user={event['user_id']} | "
                f"shard={response.get('ShardId')}"
            )

        except (ClientError, BotoCoreError) as error:

            failed += 1

            print(
                f"Event {event_number:03d} "
                f"KINESIS ERROR | {error}"
            )

        except Exception as error:

            failed += 1

            print(
                f"Event {event_number:03d} "
                f"UNEXPECTED ERROR | {error}"
            )

        if event_number < count:
            time.sleep(delay_seconds)

    print()
    print("=" * 80)
    print("KINESIS TEST SUMMARY")
    print("=" * 80)
    print(f"Total events : {count}")
    print(f"Successful   : {successful}")
    print(f"Rejected     : {rejected}")
    print(f"Failed       : {failed}")
    print("=" * 80)


# ============================================================
# CONTINUOUS STREAMING MODE
# ============================================================

def stream_to_kinesis(
    delay_range: tuple[float, float] = (0.5, 2.0),
) -> None:
    """
    Continuously generate and send events to Kinesis.

    Stop with Ctrl+C.
    """

    event_number = 0
    successful = 0
    rejected = 0
    failed = 0

    print("=" * 80)
    print("LIVE KINESIS CLICKSTREAM STREAM")
    print("=" * 80)
    print(f"Region : {AWS_REGION}")
    print(f"Stream : {KINESIS_STREAM_NAME}")
    print(
        f"Delay  : "
        f"{delay_range[0]} - {delay_range[1]} seconds"
    )
    print("Press Ctrl+C to stop.")
    print("=" * 80)

    try:

        while True:

            event_number += 1

            event = generate_event()

            # ------------------------------------------------
            # Validate
            # ------------------------------------------------

            is_valid, errors = validate_event(event)

            if not is_valid:

                rejected += 1

                print(
                    f"#{event_number:05d} "
                    f"REJECTED | "
                    f"{errors}"
                )

                time.sleep(
                    random.uniform(
                        delay_range[0],
                        delay_range[1],
                    )
                )

                continue

            # ------------------------------------------------
            # Send
            # ------------------------------------------------

            try:

                response = send_to_kinesis(event)

                successful += 1

                print(
                    f"#{event_number:05d} "
                    f"SENT | "
                    f"{event['event_type']:<18} | "
                    f"user={event['user_id']} | "
                    f"shard={response.get('ShardId')}"
                )

            except (ClientError, BotoCoreError) as error:

                failed += 1

                print(
                    f"#{event_number:05d} "
                    f"KINESIS ERROR | {error}"
                )

            except Exception as error:

                failed += 1

                print(
                    f"#{event_number:05d} "
                    f"UNEXPECTED ERROR | {error}"
                )

            # ------------------------------------------------
            # Simulate real-time delay
            # ------------------------------------------------

            time.sleep(
                random.uniform(
                    delay_range[0],
                    delay_range[1],
                )
            )

    except KeyboardInterrupt:

        print()
        print("=" * 80)
        print("KINESIS STREAM STOPPED")
        print("=" * 80)

    finally:

        print(f"Generated  : {event_number}")
        print(f"Successful : {successful}")
        print(f"Rejected   : {rejected}")
        print(f"Failed     : {failed}")
        print("=" * 80)


# ============================================================
# AWS CONNECTION TEST
# ============================================================

def test_aws_connection() -> bool:
    """
    Test basic AWS credentials and Kinesis stream access.
    """

    try:

        response = kinesis.describe_stream_summary(
            StreamName=KINESIS_STREAM_NAME
        )

        summary = response.get(
            "StreamDescriptionSummary",
            {},
        )

        status = summary.get(
            "StreamStatus",
            "UNKNOWN",
        )

        print(
            f"AWS connection successful | "
            f"Stream status: {status}"
        )

        return status == "ACTIVE"

    except (ClientError, BotoCoreError) as error:

        print(
            f"AWS/Kinesis connection failed: {error}"
        )

        return False

    except Exception as error:

        print(
            f"Unexpected AWS error: {error}"
        )

        return False


# ============================================================
# MAIN
# ============================================================

def main() -> None:
    """
    Command-line entry point.

    Commands:

        python clickstream_producer.py
            Sends 10 test events.

        python clickstream_producer.py --test 25
            Sends 25 test events.

        python clickstream_producer.py --stream
            Continuously streams events.

        python clickstream_producer.py --aws-test
            Checks AWS/Kinesis connectivity.
    """

    # --------------------------------------------------------
    # AWS connection test
    # --------------------------------------------------------

    if "--aws-test" in sys.argv:

        print("=" * 80)
        print("AWS / KINESIS CONNECTION TEST")
        print("=" * 80)

        success = test_aws_connection()

        if success:
            print("Result: PASS")
        else:
            print("Result: FAIL")

        return

    # --------------------------------------------------------
    # Continuous streaming mode
    # --------------------------------------------------------

    if "--stream" in sys.argv:

        stream_to_kinesis()

        return

    # --------------------------------------------------------
    # Custom test count
    # --------------------------------------------------------

    if "--test" in sys.argv:

        try:

            index = sys.argv.index("--test")

            count = int(sys.argv[index + 1])

            if count <= 0:
                raise ValueError(
                    "count must be greater than zero"
                )

            test_kinesis(
                count=count,
                delay_seconds=1.0,
            )

        except (IndexError, ValueError):

            print(
                "Usage: "
                "python clickstream_producer.py "
                "--test 10"
            )

        return

    # --------------------------------------------------------
    # Default = 10-event test
    # --------------------------------------------------------

    test_kinesis(
        count=10,
        delay_seconds=1.0,
    )


# ============================================================
# PROGRAM ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()