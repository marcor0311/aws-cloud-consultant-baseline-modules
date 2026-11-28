def main(event, context):
    return {
        "batchItemFailures": [
            {"itemIdentifier": record["messageId"]}
            for record in event["Records"]
            if not record["body"].strip()
        ],
    }
