def main(event, context):
    return {"request_id": context.aws_request_id}
