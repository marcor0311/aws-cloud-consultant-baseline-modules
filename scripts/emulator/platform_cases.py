"""Functional checks for the network, container, data and event modules."""

import json
from time import monotonic, sleep

TAGS = {"Project": "baseline-poc", "Environment": "test"}
ZONES = ["us-east-1a", "us-east-1b"]
PLATFORM_PROFILES = {"vpc/private", "vpc/isolated", "alb/public-https", "ecr/private", "ecs-fargate/web-service", "rds-postgres/single-az", "rds-postgres/multi-az", "sns/fan-out", "eventbridge/custom-bus", "step-functions/standard-workflow"}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def network(emulator, public=True):
    """Fixture VPC with two subnets created through the API, outside the module under test."""
    ec2 = emulator.client("ec2")
    vpc = ec2.create_vpc(CidrBlock="10.20.0.0/16")["Vpc"]["VpcId"]
    subnets = [
        ec2.create_subnet(VpcId=vpc, CidrBlock=f"10.20.{index}.0/24", AvailabilityZone=zone)["Subnet"]["SubnetId"]
        for index, zone in enumerate(ZONES)
    ]
    if public:
        gateway = ec2.create_internet_gateway()["InternetGateway"]["InternetGatewayId"]
        ec2.attach_internet_gateway(InternetGatewayId=gateway, VpcId=vpc)
    return vpc, subnets


def security_group(emulator, vpc, name):
    """AWS Emulator 1.0.385 rejects the provider's default egress revoke (ports 0 with protocol -1)."""
    return emulator.client("ec2").create_security_group(GroupName=name, Description=name, VpcId=vpc)["GroupId"]


def service_queue(emulator, name, service, source_arn):
    sqs = emulator.client("sqs")
    url = sqs.create_queue(QueueName=name)["QueueUrl"]
    arn = sqs.get_queue_attributes(QueueUrl=url, AttributeNames=["QueueArn"])["Attributes"]["QueueArn"]
    sqs.set_queue_attributes(QueueUrl=url, Attributes={"Policy": json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow", "Principal": {"Service": service}, "Action": "sqs:SendMessage", "Resource": arn,
            "Condition": {"ArnEquals": {"aws:SourceArn": source_arn}},
        }],
    })})
    return arn


def certificate(emulator):
    return emulator.client("acm").request_certificate(DomainName="probe.example.com", ValidationMethod="DNS")["CertificateArn"]


def prepare_platform(module, profile, directory, emulator):
    if module == "vpc":
        return {"name": f"probe-{profile}", "availability_zones": ZONES, "tags": TAGS}
    if module == "alb":
        vpc, subnets = network(emulator)
        return {"name": "probe-web", "vpc_id": vpc, "public_subnet_ids": subnets,
                "certificate_arn": certificate(emulator), "deletion_protection": False,
                "security_group_ids": [security_group(emulator, vpc, "probe-web-alb")], "tags": TAGS}
    if module == "ecr":
        return {"name": "probe/api", "force_delete": True, "tags": TAGS}
    if module == "ecs-fargate":
        vpc, subnets = network(emulator, public=False)
        return {"name": "probe-api", "image": "public.ecr.aws/docker/library/nginx:1.27", "vpc_id": vpc,
                "private_subnet_ids": subnets, "security_group_ids": [security_group(emulator, vpc, "probe-api-tasks")],
                "tags": TAGS}
    if module == "rds-postgres":
        vpc, subnets = network(emulator, public=False)
        return {"identifier": f"probe-{profile}", "vpc_id": vpc, "private_subnet_ids": subnets,
                "security_group_ids": [security_group(emulator, vpc, f"probe-{profile}-db")],
                "deletion_protection": False, "skip_final_snapshot": True, "tags": TAGS}
    if module == "sns":
        sqs = emulator.client("sqs")
        queues = {}
        for name in ("billing", "shipping"):
            url = sqs.create_queue(QueueName=f"probe-{name}")["QueueUrl"]
            arn = sqs.get_queue_attributes(QueueUrl=url, AttributeNames=["QueueArn"])["Attributes"]["QueueArn"]
            sqs.set_queue_attributes(QueueUrl=url, Attributes={"Policy": json.dumps({
                "Version": "2012-10-17",
                "Statement": [{
                    "Effect": "Allow", "Principal": {"Service": "sns.amazonaws.com"}, "Action": "sqs:SendMessage",
                    "Resource": arn,
                    "Condition": {"ArnEquals": {"aws:SourceArn": "arn:aws:sns:us-east-1:000000000000:probe-orders"}},
                }],
            })})
            queues[name] = arn
        return {"name": "probe-orders", "queue_arns": queues, "tags": TAGS}
    if module == "eventbridge":
        source = "arn:aws:events:us-east-1:000000000000:rule/probe-domain/order-created"
        orders = service_queue(emulator, "probe-orders", "events.amazonaws.com", source)
        dead_letter = service_queue(emulator, "probe-events-dlq", "events.amazonaws.com", source)
        return {"bus_name": "probe-domain", "orders_queue_arn": orders, "dead_letter_queue_arn": dead_letter, "tags": TAGS}
    if module == "step-functions":
        return {"name": "probe-order-workflow", "tags": TAGS}
    raise RuntimeError(f"Caso sin preparación: {module}/{profile}")


def check_vpc(profile, emulator, outputs):
    ec2 = emulator.client("ec2")
    vpc = outputs["vpc_id"]
    subnets = ec2.describe_subnets(Filters=[{"Name": "vpc-id", "Values": [vpc]}])["Subnets"]
    private = set(outputs["private_subnet_ids"])
    require(private <= {item["SubnetId"] for item in subnets} and len(private) == 2, "Faltan subredes privadas.")
    require(not any(item["MapPublicIpOnLaunch"] for item in subnets), "Una subred asigna IP pública automáticamente.")
    gateways = ec2.describe_internet_gateways(Filters=[{"Name": "attachment.vpc-id", "Values": [vpc]}])["InternetGateways"]
    nats = [item for item in ec2.describe_nat_gateways(Filter=[{"Name": "vpc-id", "Values": [vpc]}])["NatGateways"]
            if item["State"] != "deleted"]
    expected = 2 if profile == "private" else 0
    require(len(nats) == expected and len(gateways) == min(expected, 1), "Salida a Internet distinta del perfil.")
    endpoints = ec2.describe_vpc_endpoints(Filters=[{"Name": "vpc-id", "Values": [vpc]}])["VpcEndpoints"]
    require({item["ServiceName"].rsplit(".", 1)[1] for item in endpoints} == {"s3", "dynamodb"}, "Faltan endpoints de S3 y DynamoDB.")
    group = ec2.describe_security_groups(Filters=[
        {"Name": "vpc-id", "Values": [vpc]}, {"Name": "group-name", "Values": ["default"]},
    ])["SecurityGroups"][0]
    require(not group["IpPermissions"] and not group["IpPermissionsEgress"], "El grupo por defecto conserva reglas.")
    logs = ec2.describe_flow_logs(Filters=[{"Name": "resource-id", "Values": [vpc]}])["FlowLogs"]
    require(len(logs) == 1 and logs[0]["TrafficType"] == "ALL", "Falta el Flow Log de la VPC.")
    return {"vpc": vpc, "subnets": len(subnets), "nat_gateways": len(nats), "gateway_endpoints": "passed",
            "default_security_group": "closed", "flow_logs": "passed"}


def check_alb(emulator, variables, outputs):
    elb = emulator.client("elbv2")
    balancer = elb.describe_load_balancers(Names=[variables["name"]])["LoadBalancers"][0]
    require(balancer["Scheme"] == "internet-facing" and balancer["DNSName"] == outputs["dns_name"], "Balanceador distinto del esperado.")
    attributes = {item["Key"]: item["Value"] for item in
                  elb.describe_load_balancer_attributes(LoadBalancerArn=balancer["LoadBalancerArn"])["Attributes"]}
    require(attributes.get("routing.http.drop_invalid_header_fields.enabled") == "true", "No descarta cabeceras inválidas.")
    listeners = {item["Port"]: item for item in elb.describe_listeners(LoadBalancerArn=balancer["LoadBalancerArn"])["Listeners"]}
    require(set(listeners) == {80, 443}, "Faltan listeners 80 y 443.")
    require(listeners[443]["Protocol"] == "HTTPS" and listeners[443]["SslPolicy"] == "ELBSecurityPolicy-TLS13-1-2-2021-06", "HTTPS mal configurado.")
    redirect = listeners[80]["DefaultActions"][0]
    require(redirect["Type"] == "redirect" and redirect["RedirectConfig"]["Protocol"] == "HTTPS", "HTTP no redirige a HTTPS.")
    group = elb.describe_target_groups(TargetGroupArns=[outputs["target_group_arn"]])["TargetGroups"][0]
    require(group["TargetType"] == "ip" and group["HealthCheckPath"] == "/health", "Grupo de destinos incorrecto.")
    return {"load_balancer": variables["name"], "listeners": "passed", "https_redirect": "passed", "target_group": "passed"}


def check_ecr(emulator, variables, outputs):
    ecr = emulator.client("ecr")
    repository = ecr.describe_repositories(repositoryNames=[variables["name"]])["repositories"][0]
    require(repository["repositoryUri"] == outputs["repository_url"], "URL del repositorio distinta.")
    require(repository["imageTagMutability"] == "IMMUTABLE", "Las etiquetas no son inmutables.")
    require(repository["imageScanningConfiguration"]["scanOnPush"], "Falta el escaneo al publicar.")
    rules = json.loads(ecr.get_lifecycle_policy(repositoryName=variables["name"])["lifecyclePolicyText"])["rules"]
    require([rule["selection"]["tagStatus"] for rule in rules] == ["untagged", "any"], "Política de ciclo de vida incorrecta.")
    return {"repository": variables["name"], "immutable_tags": "passed", "scan_on_push": "passed", "lifecycle": "passed"}


def check_ecs(emulator, variables, outputs):
    ecs = emulator.client("ecs")
    service = ecs.describe_services(cluster=outputs["cluster_arn"], services=[outputs["service_name"]])["services"][0]
    require(service["launchType"] == "FARGATE" and service["desiredCount"] == 2, "Servicio Fargate distinto del esperado.")
    network = service["networkConfiguration"]["awsvpcConfiguration"]
    require(network["assignPublicIp"] == "DISABLED" and set(network["subnets"]) == set(variables["private_subnet_ids"]), "Red del servicio incorrecta.")
    require(service["deploymentConfiguration"]["deploymentCircuitBreaker"]["rollback"], "Falta la reversión automática.")
    task = ecs.describe_task_definition(taskDefinition=outputs["task_definition_arn"])["taskDefinition"]
    container = task["containerDefinitions"][0]
    require(task["networkMode"] == "awsvpc" and container["readonlyRootFilesystem"], "Definición de tarea incorrecta.")
    require(container["logConfiguration"]["options"]["awslogs-group"] == "/ecs/probe-api", "Logs del contenedor incorrectos.")
    return {"service": outputs["service_name"], "network": "private", "circuit_breaker": "passed", "task_definition": "passed"}


def check_rds(profile, emulator, variables, outputs):
    rds = emulator.client("rds")
    instance = rds.describe_db_instances(DBInstanceIdentifier=variables["identifier"])["DBInstances"][0]
    require(instance["Engine"] == "postgres" and instance["StorageEncrypted"], "Instancia sin cifrado o de otro motor.")
    require(not instance["PubliclyAccessible"] and instance["MultiAZ"] == (profile == "multi-az"), "Exposición o zonas incorrectas.")
    require(instance["Endpoint"]["Address"] == outputs["endpoint"], "Endpoint distinto del publicado.")
    group = instance["DBParameterGroups"][0]["DBParameterGroupName"]
    parameters = {item["ParameterName"]: item.get("ParameterValue")
                  for item in rds.describe_db_parameters(DBParameterGroupName=group, Source="user")["Parameters"]}
    require(parameters.get("rds.force_ssl") == "1", "El grupo de parámetros no exige TLS.")
    secret = emulator.client("secretsmanager").describe_secret(SecretId=outputs["master_user_secret_arn"])
    require(secret["ARN"] == outputs["master_user_secret_arn"], "No existe el secreto del usuario maestro.")
    return {"instance": variables["identifier"], "encryption": "passed", "force_ssl": "passed", "master_secret": "passed"}


def receive(emulator, queue_arn, body, timeout=30):
    sqs = emulator.client("sqs")
    url = sqs.get_queue_url(QueueName=queue_arn.rsplit(":", 1)[1])["QueueUrl"]
    deadline = monotonic() + timeout
    while monotonic() < deadline:
        for message in sqs.receive_message(QueueUrl=url, WaitTimeSeconds=2, MaxNumberOfMessages=10).get("Messages", []):
            if body in message["Body"]:
                return message["Body"]
    raise RuntimeError(f"No llegó el mensaje a {queue_arn}.")


def check_sns(emulator, variables, outputs):
    sns = emulator.client("sns")
    attributes = sns.get_topic_attributes(TopicArn=outputs["topic_arn"])["Attributes"]
    require(attributes.get("KmsMasterKeyId") == "alias/aws/sns", "El tópico no está cifrado.")
    policy = json.loads(attributes["Policy"])
    require(any(item["Effect"] == "Deny" for item in policy["Statement"]), "Falta el rechazo de tráfico sin TLS.")
    # AWS Emulator 1.0.385 evaluates aws:SecureTransport as false over HTTPS for SNS and SQS.
    # The deny is verified above and lifted only inside the emulator to test delivery, then restored.
    relaxed = {**policy, "Statement": [item for item in policy["Statement"] if item.get("Sid") != "DenyInsecureTransport"]}
    sns.set_topic_attributes(TopicArn=outputs["topic_arn"], AttributeName="Policy", AttributeValue=json.dumps(relaxed))
    try:
        body = json.dumps({"order": "probe-1"})
        sns.publish(TopicArn=outputs["topic_arn"], Message=body)
        for queue in variables["queue_arns"].values():
            require(receive(emulator, queue, "probe-1") == body, "La entrega no fue en bruto.")
    finally:
        sns.set_topic_attributes(TopicArn=outputs["topic_arn"], AttributeName="Policy", AttributeValue=attributes["Policy"])
    return {"topic": variables["name"], "encryption": "passed", "fan_out": "passed", "raw_delivery": "passed",
            "tls_deny": "verificada en la política; el emulador no evalúa aws:SecureTransport"}


def check_eventbridge(emulator, variables, outputs):
    events = emulator.client("events")
    rule = events.describe_rule(Name="order-created", EventBusName=variables["bus_name"])
    require(rule["Arn"] == outputs["rule_arns"]["order-created"], "Regla distinta de la publicada.")
    target = events.list_targets_by_rule(Rule="order-created", EventBusName=variables["bus_name"])["Targets"][0]
    require(target["DeadLetterConfig"]["Arn"] == variables["dead_letter_queue_arn"], "El destino no tiene DLQ.")
    require(target["RetryPolicy"]["MaximumEventAgeInSeconds"] == 3600, "Política de reintentos incorrecta.")
    archives = events.list_archives(EventSourceArn=events.describe_event_bus(Name=variables["bus_name"])["Arn"])["Archives"]
    require(len(archives) == 1 and archives[0]["RetentionDays"] == 7, "Falta el archivo del bus.")
    entries = [
        {"EventBusName": variables["bus_name"], "Source": "poc.orders", "DetailType": "OrderCreated", "Detail": json.dumps({"id": "probe-1"})},
        {"EventBusName": variables["bus_name"], "Source": "poc.other", "DetailType": "Ignored", "Detail": json.dumps({"id": "probe-ignored"})},
    ]
    require(events.put_events(Entries=entries)["FailedEntryCount"] == 0, "PutEvents rechazó eventos.")
    received = json.loads(receive(emulator, variables["orders_queue_arn"], "probe-1"))
    require(received["detail-type"] == "OrderCreated", "Llegó un evento distinto al filtrado.")
    return {"bus": variables["bus_name"], "pattern_routing": "passed", "dead_letter": "configured", "archive": "passed"}


def execution(emulator, machine, payload, timeout=60):
    sfn = emulator.client("stepfunctions")
    arn = sfn.start_execution(stateMachineArn=machine, input=json.dumps(payload))["executionArn"]
    deadline = monotonic() + timeout
    while monotonic() < deadline:
        result = sfn.describe_execution(executionArn=arn)
        if result["status"] != "RUNNING":
            return result
        sleep(1)
    raise RuntimeError("La ejecución no terminó a tiempo.")


def check_step_functions(emulator, variables, outputs):
    sfn = emulator.client("stepfunctions")
    machine = sfn.describe_state_machine(stateMachineArn=outputs["state_machine_arn"])
    require(machine["type"] == "STANDARD" and machine["tracingConfiguration"]["enabled"], "Flujo sin tipo Standard o sin trazas.")
    require(machine["loggingConfiguration"]["level"] == "ERROR", "Nivel de logs incorrecto.")
    accepted = execution(emulator, outputs["state_machine_arn"], {"amount": 10})
    require(accepted["status"] == "SUCCEEDED" and json.loads(accepted["output"])["result"]["status"] == "accepted", "El pedido válido no se aceptó.")
    rejected = execution(emulator, outputs["state_machine_arn"], {"amount": 0})
    require(rejected["status"] == "FAILED", "El pedido inválido no falló.")
    return {"state_machine": variables["name"], "accepted_path": "passed", "rejected_path": "passed", "tracing": "passed"}


def check_platform(module, profile, emulator, variables, outputs):
    if module == "step-functions":
        return check_step_functions(emulator, variables, outputs)
    if module == "eventbridge":
        return check_eventbridge(emulator, variables, outputs)
    if module == "sns":
        return check_sns(emulator, variables, outputs)
    if module == "rds-postgres":
        return check_rds(profile, emulator, variables, outputs)
    if module == "ecs-fargate":
        return check_ecs(emulator, variables, outputs)
    if module == "ecr":
        return check_ecr(emulator, variables, outputs)
    if module == "alb":
        return check_alb(emulator, variables, outputs)
    if module == "vpc":
        return check_vpc(profile, emulator, outputs)
    raise RuntimeError(f"Caso sin comprobación: {module}/{profile}")
