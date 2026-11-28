"""Functional probes for the Terraform examples run by test_emulator.py."""
import json
from pathlib import Path
from time import monotonic, sleep, time
from urllib.parse import unquote_plus, urlsplit
from zipfile import ZipFile

from botocore.exceptions import ClientError

ACCOUNT = "000000000000"
REGION = "us-east-1"
TAG_VALUES = {
    "Project": "baseline-poc",
    "Environment": "test",
    "Owner": "baseline-integration",
    "CostCenter": "test",
}
PROFILES = {
    "kms/iam-delegated", "kms/customer-policy",
    "sqs/standard", "sqs/standard-kms",
    "lambda/zip", "lambda/sqs-standard",
    "cloudwatch-logs/customer-managed", "cloudwatch-logs/service-managed",
    "iam/queue-worker", "iam/queue-worker-encrypted",
    "s3/default", "s3/retention",
    "dynamodb/on-demand", "dynamodb/provisioned",
}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def wait_for(description, probe, timeout=90):
    deadline = monotonic() + timeout
    while True:
        result = probe()
        if result:
            return result
        if monotonic() >= deadline:
            raise RuntimeError(f"Agotó el tiempo de espera para {description}.")
        sleep(2)


def queue_url(emulator, url):
    path = urlsplit(url).path
    require(path and path != "/", f"URL SQS sin ruta: {url}")
    return emulator.endpoint + path


def zip_handler(source: Path, archive: Path):
    with ZipFile(archive, "w") as bundle:
        bundle.write(source, source.name)


def create_key(emulator):
    return emulator.client("kms").create_key(Description="Baseline integration dependency")["KeyMetadata"]["Arn"]


def create_logs_key(emulator, name):
    group_arn = f"arn:aws:logs:{REGION}:{ACCOUNT}:log-group:{name}"
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": f"arn:aws:iam::{ACCOUNT}:root"},
                "Action": "kms:*",
                "Resource": "*",
            },
            {
                "Effect": "Allow",
                "Principal": {"Service": f"logs.{REGION}.amazonaws.com"},
                "Action": ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
                "Resource": "*",
                "Condition": {"ArnEquals": {"kms:EncryptionContext:aws:logs:arn": group_arn}},
            },
        ],
    }
    response = emulator.client("kms").create_key(
        Description="Baseline CloudWatch Logs integration dependency",
        Policy=json.dumps(policy),
    )
    return response["KeyMetadata"]["Arn"]


def prepare_lambda(profile, directory, emulator):
    name = "baseline-worker"
    group = f"/aws/lambda/{name}"
    emulator.client("logs").create_log_group(logGroupName=group)
    trust = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole",
        }],
    }
    iam = emulator.client("iam")
    role = iam.create_role(RoleName=f"{name}-execution", AssumeRolePolicyDocument=json.dumps(trust))["Role"]
    permissions = [{
        "Effect": "Allow",
        "Action": ["logs:CreateLogStream", "logs:PutLogEvents"],
        "Resource": f"arn:aws:logs:{REGION}:{ACCOUNT}:log-group:{group}:log-stream:*",
    }]
    variables = {"function_name": name, "log_group_name": group, "filename": "function.zip", "role_arn": role["Arn"]}
    if profile == "sqs-standard":
        sqs = emulator.client("sqs")
        url = queue_url(emulator, sqs.create_queue(QueueName=name, Attributes={"VisibilityTimeout": "180"})["QueueUrl"])
        arn = sqs.get_queue_attributes(QueueUrl=url, AttributeNames=["QueueArn"])["Attributes"]["QueueArn"]
        variables.update(queue_arn=arn, visibility_timeout_seconds=180)
        permissions.append({
            "Effect": "Allow",
            "Action": ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
            "Resource": arn,
        })
    iam.put_role_policy(
        RoleName=role["RoleName"],
        PolicyName="integration-fixture",
        PolicyDocument=json.dumps({"Version": "2012-10-17", "Statement": permissions}),
    )
    zip_handler(directory / "handler.py", directory / "function.zip")
    return variables


def prepare_profile(module, profile, directory, emulator):
    if module in {"kms", "sqs", "iam"}:
        from emulator.queue_cases import prepare_queue_case

        inputs = prepare_queue_case(module, profile, directory, emulator)
    elif module == "cloudwatch-logs":
        inputs = {"name": "/aws/lambda/baseline-probe", "tags": TAG_VALUES}
        if profile == "customer-managed":
            inputs["kms_key_arn"] = create_logs_key(emulator, inputs["name"])
    elif module == "lambda":
        inputs = prepare_lambda(profile, directory, emulator)
        inputs["tags"] = TAG_VALUES
    elif module == "s3":
        inputs = {"bucket_name": "baseline-emulator-documents", "kms_key_arn": create_key(emulator), "tags": TAG_VALUES}
    else:
        inputs = {"table_name": "baseline-emulator-documents", "kms_key_arn": create_key(emulator), "tags": TAG_VALUES}
    return {"aws_region": REGION, **inputs}


def check_logs(profile, emulator, variables):
    logs = emulator.client("logs")
    name = variables["name"]
    groups = logs.describe_log_groups(logGroupNamePrefix=name)["logGroups"]
    group = next((item for item in groups if item["logGroupName"] == name), None)
    require(group is not None, "CloudWatch Logs no devolvió el grupo creado.")
    require(group["retentionInDays"] == (90 if profile == "customer-managed" else 30), "Retención incorrecta.")
    require(group.get("kmsKeyId") == variables.get("kms_key_arn"), "Clave del grupo incorrecta.")
    logs.create_log_stream(logGroupName=name, logStreamName="baseline-probe")
    logs.put_log_events(logGroupName=name, logStreamName="baseline-probe", logEvents=[
        {"timestamp": int(time() * 1000), "message": "baseline-emulator-log"},
    ])
    events = logs.get_log_events(logGroupName=name, logStreamName="baseline-probe")["events"]
    require(any(event["message"] == "baseline-emulator-log" for event in events), "No se encontró el evento de prueba.")
    return {"group": name, "retention_days": group["retentionInDays"], "log_write_read": "passed"}


def check_lambda(profile, emulator, variables):
    client = emulator.client("lambda")
    name = variables["function_name"]
    configuration = client.get_function_configuration(FunctionName=name)
    require(configuration["Runtime"] == "python3.12", "Runtime Lambda incorrecto.")
    require(configuration["Role"] == variables["role_arn"], "El rol de Lambda difiere del esperado.")
    require(configuration["LoggingConfig"]["LogGroup"] == variables["log_group_name"], "Grupo de logs incorrecto.")
    payload = {}
    if profile == "sqs-standard":
        rows = client.list_event_source_mappings(FunctionName=name, EventSourceArn=variables["queue_arn"])["EventSourceMappings"]
        require(len(rows) == 1, "Lambda no devuelve un único mapeo SQS.")
        require("ReportBatchItemFailures" in rows[0]["FunctionResponseTypes"], "Falta habilitar el reporte de fallos parciales.")
        payload = {"Records": [{"messageId": "expected-failure", "body": ""}]}
    response = client.invoke(FunctionName=name, Payload=json.dumps(payload).encode())
    result = json.load(response["Payload"])
    require("FunctionError" not in response, f"Error al invocar la función ZIP: {result}")
    if profile == "sqs-standard":
        require(result == {"batchItemFailures": [{"itemIdentifier": "expected-failure"}]}, "Respuesta parcial inesperada.")
    else:
        require(bool(result.get("request_id")), "La función invocada no devolvió request_id.")
    return {"function": name, "invoke": "passed", "partial_batch": "passed" if profile == "sqs-standard" else "not_applicable"}


def check_s3(emulator, variables):
    client = emulator.client("s3")
    bucket = variables["bucket_name"]
    expected = b"baseline-s3"
    client.put_object(Bucket=bucket, Key="fixture.txt", Body=expected)
    result = client.get_object(Bucket=bucket, Key="fixture.txt")
    require(result["Body"].read() == expected, "El objeto recuperado de S3 difiere del publicado.")
    require(result.get("ServerSideEncryption") == "aws:kms", "El objeto no reportó cifrado KMS.")
    return {"bucket": bucket, "put_get": "passed", "encryption": "aws:kms"}


def check_dynamodb(emulator, variables):
    client = emulator.client("dynamodb")
    table = variables["table_name"]
    item = {"pk": {"S": "example"}, "sk": {"S": "fixture"}}
    client.put_item(TableName=table, Item=item)
    result = client.get_item(TableName=table, Key=item, ConsistentRead=True)
    require(result.get("Item") == item, "DynamoDB no devolvió el elemento esperado.")
    return {"table": table, "put_get": "passed"}


def check_functional(module, profile, emulator, variables, outputs):
    if module in {"kms", "sqs", "iam"}:
        from emulator.queue_cases import check_queue_case

        return check_queue_case(module, profile, emulator, variables, outputs)
    if module == "cloudwatch-logs":
        return check_logs(profile, emulator, variables)
    if module == "lambda":
        return check_lambda(profile, emulator, variables)
    if module == "s3":
        return check_s3(emulator, variables)
    return check_dynamodb(emulator, variables)


def check_poc(emulator, outputs):
    s3 = emulator.client("s3")
    dynamodb = emulator.client("dynamodb")
    logs = emulator.client("logs")
    sqs = emulator.client("sqs")
    iam = emulator.client("iam")
    bucket = outputs["bucket"]
    log_group = outputs["log_group"]
    table = outputs["table"]
    dlq = queue_url(emulator, outputs["dlq_url"])
    role = outputs["role"]

    trust = iam.get_role(RoleName=role)["Role"]["AssumeRolePolicyDocument"]
    require(trust["Statement"][0]["Principal"] == {"Service": "lambda.amazonaws.com"}, "Confianza IAM inesperada.")
    permissions = iam.get_role_policy(RoleName=role, PolicyName="lambda-execution")["PolicyDocument"]
    require({"ConsumeQueue", "WriteLogs", "WriteItems"} <= {item["Sid"] for item in permissions["Statement"]}, "Política de ejecución IAM incompleta.")

    success = "ready/object with space.txt"
    failure = "fail/rejected.txt"
    s3.put_object(Bucket=bucket, Key=success, Body=b"baseline-success")

    def stored():
        response = dynamodb.get_item(TableName=table, Key={"pk": {"S": success}}, ConsistentRead=True)
        return response.get("Item", {}).get("pk", {}).get("S") == success

    wait_for("el registro de S3 en DynamoDB por SQS → Lambda", stored)
    s3.put_object(Bucket=bucket, Key=failure, Body=b"baseline-failure")

    def matched_logs():
        messages = {item["message"].strip() for item in logs.filter_log_events(logGroupName=log_group)["events"]}
        return {f"fixture-stored {success}", f"fixture-rejected {failure}"} <= messages

    def dead_letter():
        messages = sqs.receive_message(QueueUrl=dlq, MaxNumberOfMessages=10, WaitTimeSeconds=0).get("Messages", [])
        for message in messages:
            keys = {unquote_plus(item["s3"]["object"]["key"]) for item in json.loads(message["Body"]).get("Records", [])}
            if failure in keys:
                sqs.delete_message(QueueUrl=dlq, ReceiptHandle=message["ReceiptHandle"])
                return True
        return False

    wait_for("los logs de la invocación exitosa y del fallo", matched_logs)
    wait_for("el mensaje rechazado en la DLQ", dead_letter, timeout=180)
    failed_item = dynamodb.get_item(TableName=table, Key={"pk": {"S": failure}}, ConsistentRead=True)
    require("Item" not in failed_item, "DynamoDB contiene el objeto que la función rechazó.")
    return {"s3_sqs_lambda_dynamodb": "passed", "cloudwatch_logs": "passed", "dead_letter_queue": "passed", "iam_provisioning": "passed"}


def remove_fixture_objects(emulator, bucket):
    client = emulator.client("s3")
    try:
        pages = client.get_paginator("list_object_versions").paginate(Bucket=bucket)
        objects = []
        for page in pages:
            for kind in ("Versions", "DeleteMarkers"):
                objects.extend({"Key": item["Key"], "VersionId": item["VersionId"]} for item in page.get(kind, []))
        for offset in range(0, len(objects), 1000):
            result = client.delete_objects(Bucket=bucket, Delete={"Objects": objects[offset:offset + 1000]})
            require(not result.get("Errors"), f"No se pudieron eliminar objetos de prueba: {result.get('Errors')}")
    except ClientError as error:
        if error.response["Error"]["Code"] not in {"NoSuchBucket", "404"}:
            raise
    return "objetos de prueba eliminados"


def prepare_destroy_dynamodb(emulator, table):
    client = emulator.client("dynamodb")
    try:
        client.update_table(TableName=table, DeletionProtectionEnabled=False)
    except client.exceptions.ResourceNotFoundException:
        return "sin tabla de prueba"
    wait_for("desactivar la protección de eliminación de DynamoDB", lambda: (
        client.describe_table(TableName=table)["Table"]["TableStatus"] == "ACTIVE"
    ))
    return "protección de eliminación desactivada"
