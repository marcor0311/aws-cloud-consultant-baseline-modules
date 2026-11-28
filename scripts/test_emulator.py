#!/usr/bin/env python3
"""Run a Terraform example against a disposable AWS Emulator."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import socket
import ssl
import subprocess
import sys
from tempfile import TemporaryDirectory
from time import monotonic, sleep
from urllib.error import URLError
from urllib.request import HTTPSHandler, ProxyHandler, build_opener
from uuid import uuid4

import boto3
from botocore.config import Config

from emulator.cases import (
    PROFILES, check_functional, check_poc, prepare_destroy_dynamodb, prepare_profile, remove_fixture_objects, zip_handler,
)

ROOT = Path(__file__).resolve().parents[1]
VERSION = "1.0.385"
IMAGE = f"baseline-poc-aws-emulator:{VERSION}"
REGION = "us-east-1"
ACCOUNT = "000000000000"
SERVICES = ("apigateway", "apigatewayv2", "cloudfront", "cloudwatchlogs", "dynamodb", "eks", "iam", "kms", "lambda", "s3", "sqs", "sts")
ENDPOINT = re.compile(r"^https://127\.0\.0\.1:[0-9]+$")
MODULE_PROFILE = re.compile(r"^[a-z][a-z0-9-]+/[a-z][a-z0-9-]+$")
CONSUMER_EXAMPLE = re.compile(r"^example:examples/[a-z][a-z0-9-]+$")
COPY_IGNORE = shutil.ignore_patterns(".terraform", "__pycache__", "*.tfstate*", "*.tfplan", "*.zip")


def run(args, cwd, env, timeout=240):
    result = subprocess.run(args, cwd=cwd, env=env, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        output = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
        raise RuntimeError(f"{args[0]} {args[1]} salió con {result.returncode}\n{output[-6500:]}")
    return result.stdout.strip()


def client_environment():
    env = {key: value for key, value in os.environ.items() if not key.upper().startswith(("AWS_", "TF_"))}
    if "TF_CLI_CONFIG_FILE" in os.environ:
        env["TF_CLI_CONFIG_FILE"] = str(Path(os.environ["TF_CLI_CONFIG_FILE"]).resolve())
    env.update(TF_INPUT="false", TF_IN_AUTOMATION="true", NO_PROXY="127.0.0.1,localhost", no_proxy="127.0.0.1,localhost")
    return env


def local_port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


class Emulator:
    def __init__(self, directory, env):
        self.directory = directory
        self.env = env
        self.container = f"baseline-emulator-{uuid4().hex[:12]}"
        self.start_attempted = False
        self.endpoint = None

    def docker(self, *args, timeout=60):
        return run(["docker", *args], self.directory, self.env, timeout)

    def start(self):
        port = local_port()
        self.endpoint = f"https://127.0.0.1:{port}"
        self.start_attempted = True
        self.docker(
            "run", "-d", "--name", self.container, "--platform", "linux/amd64",
            "--cap-drop", "ALL", "--security-opt", "no-new-privileges",
            "-e", "EMULATOR_TELEMETRY=off", "-p", f"127.0.0.1:{port}:{port}",
            IMAGE, "-p", str(port), "--idle-timeout", "600",
        )
        version = self.docker("exec", self.container, "aws-emulator", "--version")
        if f"Version: {VERSION}" not in version.splitlines():
            raise RuntimeError(f"Se esperaba AWS Emulator {VERSION}; se obtuvo {version}")
        return version.replace("\n", " · ")

    def connect(self):
        cert = self.directory / "ca.pem"
        credentials = self.directory / "emulator_credentials"
        container_dir = f"{self.container}:/home/emulator/.aws/emulator/{self.endpoint.rsplit(':', 1)[1]}"
        deadline = monotonic() + 50
        while True:
            try:
                for file in (cert, credentials):
                    self.docker("cp", f"{container_dir}/{file.name}", str(file), timeout=6)
                opener = build_opener(ProxyHandler({}), HTTPSHandler(context=ssl.create_default_context(cafile=cert)))
                with opener.open(f"{self.endpoint}/__admin/health", timeout=2) as response:
                    if response.read().strip() != b"ok":
                        raise RuntimeError("El endpoint de salud no devolvió ok.")
                break
            except (OSError, URLError, RuntimeError, subprocess.TimeoutExpired) as error:
                if monotonic() >= deadline:
                    raise RuntimeError(f"El endpoint TLS local no quedó listo: {error}") from error
                sleep(1)
        config = self.directory / "aws-config"
        config.touch()
        self.env.update(
            AWS_CA_BUNDLE=str(cert), AWS_SHARED_CREDENTIALS_FILE=str(credentials),
            AWS_CONFIG_FILE=str(config), AWS_EC2_METADATA_DISABLED="true",
            AWS_ENDPOINT_URL=self.endpoint, AWS_DISABLE_HOST_PREFIX_INJECTION="true",
            AWS_REGION=REGION, AWS_DEFAULT_REGION=REGION,
        )
        self.keys = self.read_credentials(credentials)
        identity = self.client("sts").get_caller_identity()
        if identity["Account"] != ACCOUNT:
            raise RuntimeError("La identidad de STS no pertenece a AWS Emulator.")
        return {"health": "ok", "tls": "verified", "account": identity["Account"]}

    @staticmethod
    def read_credentials(path):
        from configparser import ConfigParser

        config = ConfigParser(interpolation=None)
        config.read(path)
        return config["default"]["aws_access_key_id"], config["default"]["aws_secret_access_key"]

    def client(self, service):
        if not ENDPOINT.fullmatch(self.endpoint):
            raise RuntimeError("El SDK requiere un endpoint TLS local.")
        return boto3.client(
            service,
            region_name=REGION,
            endpoint_url=self.endpoint,
            verify=self.env["AWS_CA_BUNDLE"],
            aws_access_key_id=self.keys[0],
            aws_secret_access_key=self.keys[1],
            config=Config(
                connect_timeout=4, read_timeout=12, retries={"total_max_attempts": 1},
                proxies={}, inject_host_prefix=False, s3={"addressing_style": "path"},
            ),
        )

    def stop(self):
        if self.start_attempted:
            result = subprocess.run(
                ["docker", "rm", "-f", self.container], cwd=self.directory, env=self.env,
                capture_output=True, text=True, timeout=60,
            )
            if result.returncode and "No such container" not in result.stderr:
                raise RuntimeError(result.stderr.strip())
        return "contenedor efímero eliminado"



def stage_case(root, case, tree, emulator):
    shutil.copytree(root / "aws", tree / "aws", ignore=COPY_IGNORE)
    if (root / "examples").is_dir():
        shutil.copytree(root / "examples", tree / "examples", ignore=COPY_IGNORE)
    if case == "poc":
        target = tree / "examples/poc-emulator"
        zip_handler(target / "fixture.py", target / "fixture.zip")
        variables = dict(endpoint=emulator.endpoint, account=ACCOUNT, prefix="baseline-poc")
    elif case in PROFILES:
        module, profile = case.split("/")
        target = tree / "aws" / module / "examples" / profile
        variables = prepare_profile(module, profile, target, emulator)
    else:
        if case.startswith("example:"):
            target = tree / case.removeprefix("example:")
        else:
            module, profile = case.split("/")
            target = tree / "aws" / module / "examples" / profile
        if not target.is_dir() or not any(target.glob("*.tf")):
            raise RuntimeError(f"Ejemplo Terraform ausente: {case}")
        sample = target / "terraform.tfvars.example"
        if sample.exists():
            shutil.copyfile(sample, target / "terraform.tfvars")
        variables = {}
    if not (target / ".terraform.lock.hcl").exists():
        shutil.copy(root / "aws/s3/.terraform.lock.hcl", target / ".terraform.lock.hcl")
    # Terraform override files preserve the published example and replace only the test provider.
    provider = {
        "region": REGION, "s3_use_path_style": True, "skip_credentials_validation": True,
        "skip_metadata_api_check": True, "skip_region_validation": True,
        "skip_requesting_account_id": True,
        "endpoints": [{service: emulator.endpoint for service in SERVICES}],
    }
    (target / "emulator_override.tf.json").write_text(json.dumps({"provider": {"aws": provider}}))
    (target / "test.auto.tfvars.json").write_text(json.dumps(variables))
    return target, variables


def check_state(terraform):
    state = json.loads(terraform("show", "-json"))
    root_module = state.get("values", {}).get("root_module", {})

    def managed_resources(module):
        for item in module.get("resources", []):
            if item["mode"] == "managed":
                yield item["address"]
        for child in module.get("child_modules", []):
            yield from managed_resources(child)

    managed = list(managed_resources(root_module))
    if not managed:
        raise RuntimeError("El ejemplo no aprovisionó recursos gestionados para comprobar.")
    terraform("plan", "-detailed-exitcode", "-no-color")
    return {
        "managed_resources": managed,
        "read_and_reconcile": "passed",
        "coverage": "lectura de recursos tras apply y convergencia del plan",
    }


def terraform_summary(terraform, *args):
    output = terraform(*args)
    for line in output.splitlines():
        if line.startswith(("Plan:", "Apply complete!", "Destroy complete!", "Terraform has been successfully initialized!")):
            return line
    return output[-1500:]


def record_phase(report, name, operation):
    started = monotonic()
    try:
        result = operation()
    except Exception as error:
        report["steps"][name] = {"status": "failed", "seconds": round(monotonic() - started, 2), "detail": str(error)}
        print(f"{name}: fallo. {error}", file=sys.stderr, flush=True)
        raise
    report["steps"][name] = {"status": "passed", "seconds": round(monotonic() - started, 2), "detail": result}
    print(f"{name}: correcto", flush=True)
    return result


def execute(root, case):
    report = {
        "case": case, "date": datetime.now(timezone.utc).isoformat(), "aws_emulator": VERSION, "steps": {},
        "limitations": [
            "AWS Emulator conserva el estado en memoria y usa una sola cuenta y región.",
            "Los resultados IAM y KMS demuestran aprovisionamiento y comportamiento local. La autorización y la aplicación de políticas en AWS requieren pruebas independientes.",
            "KMS programa la eliminación de claves; la terminación del contenedor elimina el estado restante.",
        ],
    }
    work = None
    variables = {}
    apply_started = False
    env = client_environment()
    with TemporaryDirectory(prefix="baseline-emulator-") as directory:
        directory = Path(directory)
        emulator = Emulator(directory, env)

        def terraform(*args):
            return run(["terraform", *args], work or directory, env)

        def verify():
            if case not in PROFILES and case != "poc":
                return check_state(terraform)
            outputs = {key: item["value"] for key, item in json.loads(terraform("output", "-json")).items()}
            if case == "poc":
                return check_poc(emulator, outputs["fixture"])
            return check_functional(*case.split("/"), emulator=emulator, variables=variables, outputs=outputs)

        try:
            record_phase(report, "emulator_version", emulator.start)
            record_phase(report, "health", emulator.connect)
            record_phase(report, "terraform_version", lambda: json.loads(terraform("version", "-json"))["terraform_version"])
            work, variables = record_phase(
                report, "prepare", lambda: stage_case(root, case, directory / "tree", emulator)
            )
            report["steps"]["prepare"]["detail"] = "ejemplo de consumo y dependencias de prueba"
            record_phase(report, "init", lambda: terraform_summary(terraform, "init", "-backend=false", "-lockfile=readonly", "-no-color"))
            record_phase(report, "plan", lambda: terraform_summary(terraform, "plan", "-no-color", "-out=integration.tfplan"))
            apply_started = True
            record_phase(report, "apply", lambda: terraform_summary(terraform, "apply", "-no-color", "integration.tfplan"))
            record_phase(report, "functional", verify)
        except Exception:
            pass
        finally:
            if apply_started:
                if case == "poc" or case.startswith("s3/"):
                    bucket = f"{variables['prefix']}-objects" if case == "poc" else variables["bucket_name"]
                    try:
                        record_phase(report, "empty_fixture_bucket", lambda: remove_fixture_objects(emulator, bucket))
                    except Exception:
                        pass
                if case.startswith("dynamodb/"):
                    try:
                        record_phase(
                            report, "disable_fixture_deletion_protection",
                            lambda: prepare_destroy_dynamodb(emulator, variables["table_name"]),
                        )
                    except Exception:
                        pass
                try:
                    record_phase(report, "destroy", lambda: terraform_summary(terraform, "destroy", "-auto-approve", "-no-color"))
                except Exception:
                    pass
            try:
                record_phase(report, "cleanup", emulator.stop)
            except Exception:
                pass
    for name in ("emulator_version", "health", "terraform_version", "prepare", "init", "plan", "apply", "functional", "destroy", "cleanup"):
        report["steps"].setdefault(name, {"status": "not_run"})
    report["status"] = "passed" if all(step["status"] == "passed" for step in report["steps"].values()) else "failed"
    if case not in PROFILES and case != "poc":
        report["limitations"].append("Este ejemplo comprueba lectura y convergencia de los recursos. Sus operaciones de datos requieren un adaptador funcional.")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", required=True, help="módulo/perfil o poc")
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--root", type=Path, default=ROOT, help="checkout con los módulos del caso")
    args = parser.parse_args()
    case = "poc" if args.case == "example:examples/poc-emulator" else args.case
    if case != "poc" and not (MODULE_PROFILE.fullmatch(case) or CONSUMER_EXAMPLE.fullmatch(case)):
        parser.error(f"El caso debe ser módulo/perfil, example:examples/<nombre> o poc: {case}")
    evidence = execute(args.root.resolve(), case)
    document = json.dumps(evidence, ensure_ascii=False, indent=2) + "\n"
    if args.evidence:
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(document, encoding="utf-8")
    print(document, end="")
    return 0 if evidence["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
