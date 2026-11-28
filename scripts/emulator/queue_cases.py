"""Functional checks for the KMS, SQS and Lambda execution role examples."""

import json
from time import monotonic, sleep
from urllib.parse import unquote, urlsplit


REGION = "us-east-1"
ACCOUNT = "000000000000"


def prepare_queue_case(module, profile, _directory, emulator):
    if module == "kms":
        if profile == "customer-policy":
            return {
                "alias_name": "alias/poc-logs",
                "aws_account_id": ACCOUNT,
                "log_group_name": "/aws/lambda/poc-object-processor",
            }
        return {"alias_name": "alias/poc-objects"}
    if module == "sqs":
        if profile == "standard-kms":
            key = emulator.client("kms").create_key(Description="Ephemeral SQS fixture")["KeyMetadata"]
            return {"queue_name": "poc-events-kms", "kms_key_arn": key["Arn"]}
        return {
            "queue_name": "poc-events",
            "source_bucket_arn": "arn:aws:s3:::poc-inbound-documents",
            "source_account_id": ACCOUNT,
        }
    if module != "iam":
        raise ValueError(f"El adaptador no conoce el módulo {module}")
    variables = {
        "role_name": "poc-emulator-worker",
        "queue_arns": [f"arn:aws:sqs:{REGION}:{ACCOUNT}:poc-emulator-events"],
        "log_group_arns": [f"arn:aws:logs:{REGION}:{ACCOUNT}:log-group:/aws/lambda/poc-emulator-worker"],
        "dynamodb_table_arns": [f"arn:aws:dynamodb:{REGION}:{ACCOUNT}:table/poc-emulator-results"],
        "tags": {"Environment": "example"},
    }
    if profile == "queue-worker-encrypted":
        key = emulator.client("kms").create_key(Description="Ephemeral IAM fixture")["KeyMetadata"]
        variables.update(
            s3_object_arns=["arn:aws:s3:::poc-emulator-assets/incoming/*"],
            kms_key_arns=[key["Arn"]],
        )
    return variables


def require(condition, detail):
    if not condition:
        raise RuntimeError(detail)


def document(policy):
    return json.loads(unquote(policy)) if isinstance(policy, str) else policy


def values(value):
    return {value} if isinstance(value, str) else set(value)


def check_kms(profile, emulator, variables, outputs):
    kms = emulator.client("kms")
    arn = outputs["key_arn"]
    metadata = kms.describe_key(KeyId=arn)["KeyMetadata"]
    require(metadata["Arn"] == arn and metadata["KeyManager"] == "CUSTOMER", "KMS no devolvió la clave de cliente esperada.")
    require(
        metadata["KeyUsage"] == "ENCRYPT_DECRYPT" and metadata["KeySpec"] == "SYMMETRIC_DEFAULT",
        "KMS no aprovisionó una clave simétrica de cifrado y descifrado.",
    )
    key_id = metadata["KeyId"]
    require(kms.get_key_rotation_status(KeyId=key_id)["KeyRotationEnabled"], "La clave KMS no tiene rotación habilitada.")
    aliases = kms.list_aliases(KeyId=key_id)["Aliases"]
    require(
        any(alias["AliasName"] == variables["alias_name"] and alias["TargetKeyId"] == key_id for alias in aliases),
        "El alias no apunta a la clave del módulo.",
    )
    plaintext = b"baseline-kms-emulator"
    ciphertext = kms.encrypt(KeyId=key_id, Plaintext=plaintext)["CiphertextBlob"]
    require(ciphertext != plaintext and kms.decrypt(CiphertextBlob=ciphertext)["Plaintext"] == plaintext, "Falló el cifrado y descifrado KMS.")
    result = {"key": "simétrica regional", "alias": "coincide", "rotation": "habilitada", "encrypt_decrypt": "verificado"}
    if profile == "customer-policy":
        policy = document(kms.get_key_policy(KeyId=key_id, PolicyName="default")["Policy"])
        statements = {item.get("Sid"): item for item in policy["Statement"]}
        delegation = statements["EnableAccountIAM"]
        logs = statements["AllowCloudWatchLogs"]
        require(
            values(delegation["Principal"]["AWS"]) == {f"arn:aws:iam::{ACCOUNT}:root"},
            "La política KMS no conservó la delegación de IAM de la cuenta.",
        )
        expected_group = f"arn:aws:logs:{REGION}:{ACCOUNT}:log-group:{variables['log_group_name']}"
        require(
            values(logs["Principal"]["Service"]) == {f"logs.{REGION}.amazonaws.com"}
            and values(logs["Condition"]["ArnEquals"]["kms:EncryptionContext:aws:logs:arn"]) == {expected_group},
            "La política KMS no mantuvo el alcance del grupo de Logs esperado.",
        )
        result["policy"] = "contenido de la política de clave verificado"
    return result


def queue_url(emulator, reported):
    parsed = urlsplit(reported)
    require(parsed.path.startswith("/") and parsed.path != "/", "SQS no devolvió una ruta de cola en su URL.")
    return f"{emulator.endpoint}{parsed.path}"


def wait_for_message(sqs, address, *, body, timeout=10):
    deadline = monotonic() + timeout
    while monotonic() < deadline:
        response = sqs.receive_message(QueueUrl=address, WaitTimeSeconds=0, MaxNumberOfMessages=1)
        messages = response.get("Messages", [])
        if messages:
            require(messages[0]["Body"] == body, "SQS devolvió un mensaje distinto al enviado.")
            return messages[0]
        sleep(0.2)
    raise RuntimeError("SQS no entregó el mensaje dentro del plazo.")


def check_sqs(profile, emulator, variables, outputs):
    sqs = emulator.client("sqs")
    queue_name = variables["queue_name"]
    source = queue_url(emulator, sqs.get_queue_url(QueueName=queue_name)["QueueUrl"])
    dead_letter = queue_url(emulator, outputs["dead_letter_queue_url"])
    attributes = sqs.get_queue_attributes(QueueUrl=source, AttributeNames=["All"])["Attributes"]
    dlq_attributes = sqs.get_queue_attributes(QueueUrl=dead_letter, AttributeNames=["All"])["Attributes"]
    require(attributes["QueueArn"] == outputs["queue_arn"], "SQS devolvió un ARN distinto al output de Terraform.")
    redrive = document(attributes["RedrivePolicy"])
    require(
        redrive["deadLetterTargetArn"] == dlq_attributes["QueueArn"] and int(redrive["maxReceiveCount"]) == 5,
        "La cola de origen no tiene el destino y el número de recepciones configurados.",
    )
    allowed = document(dlq_attributes["RedriveAllowPolicy"])
    require(
        allowed["redrivePermission"] == "byQueue" and allowed["sourceQueueArns"] == [outputs["queue_arn"]],
        "La DLQ no restringió la redirección a la cola fuente.",
    )
    for current in (attributes, dlq_attributes):
        if profile == "standard-kms":
            require(current["KmsMasterKeyId"] == variables["kms_key_arn"], "SQS no aplicó la clave KMS a ambas colas.")
        else:
            require(current.get("SqsManagedSseEnabled") == "true", "SQS no activó SSE-SQS para ambas colas.")
    if profile == "standard":
        policy = document(attributes["Policy"])
        producer = next(item for item in policy["Statement"] if item["Sid"] == "AllowS3Source")
        require(
            producer["Principal"]["Service"] == "s3.amazonaws.com"
            and producer["Condition"]["ArnEquals"]["aws:SourceArn"] == variables["source_bucket_arn"]
            and producer["Condition"]["StringEquals"]["aws:SourceAccount"] == variables["source_account_id"],
            "La cola no conservó el alcance del productor S3 autorizado.",
        )
    body = "baseline-sqs-emulator"
    sqs.send_message(QueueUrl=source, MessageBody=body)
    message = wait_for_message(sqs, source, body=body)
    sqs.delete_message(QueueUrl=source, ReceiptHandle=message["ReceiptHandle"])
    return {"encryption": profile, "message_roundtrip": "enviado, recibido y borrado", "redrive": "políticas fuente y DLQ verificadas"}


def check_iam(emulator, variables, outputs):
    iam = emulator.client("iam")
    role_name = variables["role_name"]
    role = iam.get_role(RoleName=role_name)["Role"]
    require(role["Arn"] == outputs["role_arn"], "IAM devolvió un ARN distinto al output de Terraform.")
    trust = document(role["AssumeRolePolicyDocument"])["Statement"]
    require(
        len(trust) == 1 and trust[0]["Effect"] == "Allow"
        and values(trust[0]["Action"]) == {"sts:AssumeRole"}
        and values(trust[0]["Principal"]["Service"]) == {"lambda.amazonaws.com"},
        "El rol IAM no conservó la confianza exclusiva en Lambda.",
    )
    require(
        iam.list_role_policies(RoleName=role_name)["PolicyNames"] == ["lambda-execution"],
        "El rol no tiene la política inline esperada.",
    )
    inline = iam.get_role_policy(RoleName=role_name, PolicyName="lambda-execution")
    configured = document(inline["PolicyDocument"])["Statement"]
    expected = {
        "ConsumeQueue": ({"sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"}, set(variables["queue_arns"])),
        "WriteLogs": ({"logs:CreateLogStream", "logs:PutLogEvents"}, {arn.removesuffix(":*") + ":log-stream:*" for arn in variables["log_group_arns"]}),
        "WriteItems": ({"dynamodb:PutItem"}, set(variables["dynamodb_table_arns"])),
    }
    if "s3_object_arns" in variables:
        expected["ReadObjects"] = ({"s3:GetObject"}, set(variables["s3_object_arns"]))
        expected["DecryptData"] = ({"kms:Decrypt"}, set(variables["kms_key_arns"]))
    require(all(item["Effect"] == "Allow" for item in configured), "Se encontraron efectos IAM inesperados.")
    observed = {item["Sid"]: (values(item["Action"]), values(item["Resource"])) for item in configured}
    require(observed == expected, "Las acciones o los ARN de la política inline no son los esperados.")
    return {"role": "consultado", "trust": "solo Lambda", "inline_policy": sorted(observed), "authorization": "fuera del alcance de esta prueba de aprovisionamiento"}


def check_queue_case(module, profile, emulator, variables, outputs):
    if module == "kms":
        return check_kms(profile, emulator, variables, outputs)
    if module == "sqs":
        return check_sqs(profile, emulator, variables, outputs)
    if module == "iam":
        return check_iam(emulator, variables, outputs)
    raise ValueError(f"El adaptador no conoce el módulo {module}")
