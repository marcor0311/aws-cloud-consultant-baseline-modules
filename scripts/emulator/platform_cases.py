"""Functional checks for the network, container, data and event modules."""

TAGS = {"Project": "baseline-poc", "Environment": "test"}
ZONES = ["us-east-1a", "us-east-1b"]
PLATFORM_PROFILES = {"vpc/private", "vpc/isolated"}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def prepare_platform(module, profile, directory, emulator):
    if module == "vpc":
        return {"name": f"probe-{profile}", "availability_zones": ZONES, "tags": TAGS}
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


def check_platform(module, profile, emulator, variables, outputs):
    if module == "vpc":
        return check_vpc(profile, emulator, outputs)
    raise RuntimeError(f"Caso sin comprobación: {module}/{profile}")
