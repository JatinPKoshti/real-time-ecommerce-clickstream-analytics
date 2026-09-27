from producer.clickstream_producer import validate_event


bad_event = {
    "event_id": "",
    "event_timestamp": "",
    "user_id": "U10001",
    "session_id": "S10001",
    "event_type": "wrong_event",
    "product_id": "P1001",
    "product_name": "Test Product",
    "category": "Test",
    "price": -500,
    "quantity": -1,
    "device": "mobile",
    "browser": "Chrome",
    "city": "Ahmedabad",
    "country": "India",
}


valid, errors = validate_event(bad_event)

print("Valid:", valid)
print("Errors:")

for error in errors:
    print("-", error)