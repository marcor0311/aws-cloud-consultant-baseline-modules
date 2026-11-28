"""Functional checks for the network, container, data and event modules."""

TAGS = {"Project": "baseline-poc", "Environment": "test"}
ZONES = ["us-east-1a", "us-east-1b"]
PLATFORM_PROFILES = {"vpc/private", "vpc/isolated", "alb/public-https"}


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


def check_platform(module, profile, emulator, variables, outputs):
    if module == "alb":
        return check_alb(emulator, variables, outputs)
    if module == "vpc":
        return check_vpc(profile, emulator, outputs)
    raise RuntimeError(f"Caso sin comprobación: {module}/{profile}")
