#!/usr/bin/env python3
"""Inspect the baseline catalog and calculate a regional, monthly AWS selection."""

import argparse
import json
import re
import subprocess
import sys
from decimal import Decimal, InvalidOperation
from pathlib import Path, PurePosixPath

import yaml


ROOT = Path(__file__).resolve().parent.parent
REMOTE = "https://github.com/marcor0311/aws-cloud-consultant-baseline-modules"
REPOSITORY = f"{REMOTE}.git"
ORIGIN_URLS = {REMOTE, REPOSITORY, "git@github.com:marcor0311/aws-cloud-consultant-baseline-modules.git"}


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def catalog(ref=None):
    revision = None
    published = False
    if ref:
        revision = git("rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}")
        tracking = git("for-each-ref", "--format=%(refname)", "--contains", revision, "refs/remotes/origin/")
        published = bool(tracking) and git("remote", "get-url", "origin") in ORIGIN_URLS

    if revision:
        files = set(git("ls-tree", "-r", "--name-only", revision).splitlines())

        def read(path):
            return yaml.safe_load(git("show", f"{revision}:{path}"))

        def exists(path):
            return path in files

        manifests = sorted(path for path in files if re.fullmatch(r"aws/[^/]+/module\.yaml", path))
    else:
        def read(path):
            return yaml.safe_load((ROOT / path).read_text(encoding="utf-8"))

        def exists(path):
            return (ROOT / path).is_file()

        manifests = sorted(path.relative_to(ROOT).as_posix() for path in ROOT.glob("aws/*/module.yaml"))

    if not manifests:
        raise ValueError("El catálogo no contiene módulos.")

    modules = {}
    for path in manifests:
        directory = PurePosixPath(path).parent
        module = read(path)
        audit_path = str(directory / "audit-record.yaml")
        audit = read(audit_path)
        if module["module_id"] != directory.name or audit["module_id"] != directory.name:
            raise ValueError(f"Identificador de módulo incoherente en {directory}.")

        profiles = {}
        for profile in module["profiles"]:
            name = profile["name"]
            example = directory / profile["example"]
            if name in profiles or not exists(str(example / "main.tf")):
                raise ValueError(f"Perfil duplicado o sin Terraform en {directory}/{name}.")
            profiles[name] = {**profile, "example": str(example)}

        readme = str(directory / module["readme"])
        checks = audit.get("validation_evidence") or {}
        tests = str(directory / checks["test_definitions"]) if "test_definitions" in checks else None
        source_directory = directory / module["entrypoint"]
        consumer = module.get("consumer")
        evidence_files = [readme, str(source_directory / "main.tf"), tests]
        if consumer:
            evidence_files.append(consumer.get("diagram"))
        modules[directory.name] = {
            "candidate_version": module["candidate_version"],
            "status": module["status"],
            "commit": revision,
            "published_in_origin": published,
            "source": f"git::{REPOSITORY}//{source_directory}?ref={revision}" if revision else None,
            "terraform": module["terraform"],
            "aws_provider": module["aws_provider"],
            "manifest": path,
            "readme": readme,
            "audit_record": audit_path,
            "audit": audit,
            "review": {
                "implementation": audit["implementation_review"],
                "production": audit["production_approval"],
                "aws_integration": audit["aws_integration_validation"],
                "approved_commit": audit.get("approved_commit"),
            },
            "missing_files": [item for item in evidence_files if item and not exists(item)],
            "consumer": consumer,
            "profiles": profiles,
        }
    return modules


def amount(value):
    number = Decimal(str(value))
    if not number.is_finite() or number < 0:
        raise ValueError(f"Se esperaba un número finito no negativo, se recibió {value!r}.")
    return number


def tier_cost(quantity, tiers, meter):
    if not tiers:
        raise ValueError(f"{meter} requiere al menos un tramo de precio.")
    total = Decimal(0)
    lower_bound = Decimal(0)
    for index, tier in enumerate(tiers):
        start = amount(tier["start"])
        end = Decimal("Infinity") if tier["end"] == "Inf" else amount(tier["end"])
        if start != lower_bound or end <= start:
            raise ValueError(f"Tramos no contiguos o invertidos para {meter}.")
        if end.is_infinite() and index < len(tiers) - 1:
            raise ValueError(f"Un tramo ilimitado debe ir al final para {meter}.")
        total += max(min(quantity, end) - start, Decimal(0)) * amount(tier["price"])
        lower_bound = end
    return total if quantity <= lower_bound else None


def priced_group(name, required, usage, rates):
    rows = []
    total = Decimal(0)
    for meter in sorted(set(required) | set(usage)):
        used = usage.get(meter)
        rate = rates.get(meter)
        cost = None
        if used is None:
            reason = "uso pendiente"
        else:
            quantity = amount(used)
            if quantity == 0:
                cost, reason = Decimal(0), None
            elif rate is None:
                reason = "tarifa pendiente"
            else:
                if any(not rate.get(field) for field in ("sku", "unit", "source", "effective_on")):
                    raise ValueError(f"La tarifa de {meter} requiere SKU, unidad, fuente y fecha efectiva.")
                cost = tier_cost(quantity, rate["tiers"], meter)
                reason = "fuera de los tramos disponibles" if cost is None else None
        if cost is not None:
            total += cost
        rows.append({
            "meter": meter,
            "quantity": used,
            "rate": rate,
            "cost": str(cost) if cost is not None else None,
            "pending": reason,
        })
    return {"name": name, "lines": rows, "known_monthly_cost": str(total)}


def estimate(request, quotes, modules):
    if any(request[key] != quotes[key] for key in ("region", "currency")):
        raise ValueError("La región y la moneda de la solicitud deben coincidir con las tarifas.")
    if not request["assumptions"] or not request["scenarios"]:
        raise ValueError("Incluye supuestos y al menos un escenario.")

    results = []
    names = set()
    for scenario in request["scenarios"]:
        if scenario["name"] in names or not scenario["modules"]:
            raise ValueError("Cada escenario requiere un nombre único y al menos un módulo.")
        names.add(scenario["name"])
        groups = []
        selected, shared = set(), set()
        for item in scenario["modules"]:
            module, profile = item["module"], item["profile"]
            if module in selected:
                raise ValueError(f"Selecciona un solo perfil de {module} por escenario.")
            selected.add(module)
            pricing = modules[module]["profiles"][profile].get("pricing")
            if not pricing:
                pricing = {"meters": [f"modelo-pendiente:{module}/{profile}"], "shared": []}
            groups.append(priced_group(f"{module}/{profile}", pricing["meters"], item["usage"], quotes["rates"]))
            shared.update(pricing["shared"])

        groups.append(priced_group("dependencias compartidas", shared, scenario.get("shared_usage", {}), quotes["rates"]))
        meters = [line["meter"] for group in groups for line in group["lines"]]
        if len(meters) != len(set(meters)):
            raise ValueError("Agrupa cada dimensión de cobro compartida una sola vez.")
        partial = any(line["pending"] for group in groups for line in group["lines"])
        known = sum((Decimal(group["known_monthly_cost"]) for group in groups), Decimal(0))
        results.append({
            "name": scenario["name"], "status": "partial" if partial else "estimated",
            "known_monthly_cost": f"{known:.2f}", "monthly_total": None if partial else f"{known:.2f}",
            "groups": groups,
        })

    return {
        "region": request["region"], "currency": request["currency"],
        "quoted_on": quotes["quoted_on"], "assumptions": request["assumptions"],
        "exclusions": request.get("exclusions", []), "scenarios": results,
    }


def shopping_list(request, quotes, modules):
    result = estimate(request, quotes, modules)
    result["source_issue"] = request.get("source_issue")
    result["gaps"] = request.get("gaps", [])
    for scenario, costs in zip(request["scenarios"], result["scenarios"], strict=True):
        costs["options"] = []
        for item, group in zip(scenario["modules"], costs["groups"][:-1], strict=True):
            module_id, profile_name = item["module"], item["profile"]
            module = modules[module_id]
            profile = module["profiles"][profile_name]
            consumer = module["consumer"] or {}
            configuration = item.get("configuration", {})
            if not isinstance(configuration, dict):
                raise ValueError(f"La configuración de {module_id}/{profile_name} debe ser un objeto JSON.")
            required_inputs = [*consumer.get("required_inputs", []), *profile.get("required_inputs", [])]

            selection = None
            pending = []
            if not module["published_in_origin"]:
                pending.append("referencia por publicar o verificar con origin")
            if module["missing_files"]:
                pending.append("faltan archivos de evidencia o contrato")
            # An audit declaration is not GitHub evidence for this exact revision.
            if module["review"]["production"] == "approved":
                pending.append("verificar aprobación del arquitecto para el commit exacto")
            elif module["review"]["production"] != "pending":
                pending.append("revisar el estado de producción del módulo")
            if not pending:
                selection = {
                    "module_id": module_id,
                    "repository": REPOSITORY,
                    "commit": module["commit"],
                    "candidate_version": module["candidate_version"],
                    "approval_status": "draft",
                    "profile": profile_name,
                    "configuration": configuration,
                }
            costs["options"].append({
                "module_id": module_id, "profile": profile_name,
                "capability": item.get("requirement", consumer.get("capability")),
                "fit": profile.get("fit"),
                "candidate_version": module["candidate_version"],
                "commit": module["commit"], "terraform_source": module["source"],
                "example": profile["example"], "readme": module["readme"],
                "required_inputs": required_inputs,
                "dependencies": [*consumer.get("dependencies", []), *profile.get("dependencies", [])],
                "controls": consumer.get("controls", []), "limits": consumer.get("limits", []),
                "evidence": {"audit_record": module["audit_record"], "diagram": consumer.get("diagram"),
                             "review": module["review"], "missing_files": module["missing_files"]},
                "known_direct_monthly_cost": f"{Decimal(group['known_monthly_cost']):.2f}",
                "direct_cost_status": "partial" if any(line["pending"] for line in group["lines"]) else "estimated",
                "selection": selection, "selection_pending": pending,
            })
    return result


def markdown_cell(value):
    return str(value or "Pendiente").replace("|", "\\|").replace("\n", " ").replace("\r", " ")


def shopping_list_markdown(result):
    lines = ["# Selección de módulos baseline", "",
             f"Región `{result['region']}` · {result['currency']} al mes · tarifas del {result['quoted_on']}"]
    if result["source_issue"]:
        lines.append(f"Issue de origen {markdown_cell(result['source_issue'])}")
    unique_options = {}
    for scenario in result["scenarios"]:
        shared = f"{Decimal(scenario['groups'][-1]['known_monthly_cost']):.2f}"
        total = scenario["monthly_total"]
        summary = f"Total estimado {total}" if total is not None else f"Subtotal conocido {scenario['known_monthly_cost']} (parcial)"
        lines.extend(["", f"## {markdown_cell(scenario['name'])}", "", f"{summary} · Dependencias compartidas {shared}", "",
                      "| Módulo y perfil | Necesidad y elección | Cargo directo | Estado y referencia |",
                      "| --- | --- | ---: | --- |"])
        for option in scenario["options"]:
            name = f"{option['module_id']}/{option['profile']}"
            unique_options.setdefault(name, option)
            direct_cost = option["known_direct_monthly_cost"]
            if option["direct_cost_status"] == "partial":
                direct_cost += " (parcial)"
            status = option["evidence"]["review"]["production"]
            review = {"pending": "aprobación pendiente", "approved": "aprobación registrada"}.get(status, status)
            reference = f"{option['candidate_version']} · {review} · {option['commit'] or 'árbol de trabajo'}"
            capability = (option["capability"] or "Necesidad por confirmar").rstrip(".")
            row = [name, f"{capability}. {option['fit'] or 'Perfil por revisar'}", direct_cost, reference]
            lines.append("| " + " | ".join(map(markdown_cell, row)) + " |")
        if scenario["status"] == "partial":
            lines.extend(["", "### Partidas pendientes", ""])
        for group in scenario["groups"]:
            for line in group["lines"]:
                if line["pending"]:
                    lines.append(f"- {group['name']} · `{line['meter']}` · {line['pending']}")
    lines.extend(["", "## Contrato de los perfiles"])
    for name, option in unique_options.items():
        lines.extend(["", f"### `{name}`", "",
                      f"- Ejemplo `{option['example']}` · contrato `{option['readme']}`",
                      f"- Entradas requeridas {', '.join(option['required_inputs']) or 'por revisar'}",
                      f"- Dependencias {', '.join(option['dependencies']) or 'por revisar'}",
                      f"- Controles {', '.join(option['controls']) or 'por revisar'}",
                      f"- Límites {', '.join(option['limits']) or 'por revisar'}",
                      f"- Evidencia `{option['evidence']['audit_record']}`"])
        if option["evidence"]["diagram"]:
            lines.append(f"- Diagrama `{option['evidence']['diagram']}`")
        if option["selection"]:
            lines.append(f"- Fuente Terraform `{option['terraform_source']}`")
        else:
            lines.append(f"- Selección pendiente · {' · '.join(option['selection_pending'])}")
    if result["gaps"]:
        lines.extend(["", "## Capacidades faltantes", "", *[f"- {gap}" for gap in result["gaps"]]])
    lines.extend(["", "## Supuestos de uso", "", *[f"- {value}" for value in result["assumptions"]]])
    if result["exclusions"]:
        lines.extend(["", "## Exclusiones", "", *[f"- {value}" for value in result["exclusions"]]])
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    listing = commands.add_parser("catalog", help="Inspect modules, profiles, provenance and review state")
    listing.add_argument("--ref", help="Read a committed Git tree instead of the working tree")
    calculator = commands.add_parser("estimate", help="Estimate monthly usage against AWS rates")
    selection = commands.add_parser("shopping-list", help="Combine catalog options, monthly cost and selections for Architecture")
    for command in (calculator, selection):
        command.add_argument("request", type=Path)
        command.add_argument("rates", type=Path)
        command.add_argument("--ref", help="Read the module contract at this Git revision")
    selection.add_argument("--format", choices=("json", "markdown"), default="json")
    args = parser.parse_args()

    try:
        modules = catalog(args.ref)
        data = {"modules": modules}
        if args.command != "catalog":
            request = json.loads(args.request.read_text())
            quotes = json.loads(args.rates.read_text())
            data = (estimate if args.command == "estimate" else shopping_list)(request, quotes, modules)
    except (OSError, ValueError, KeyError, TypeError, InvalidOperation, subprocess.CalledProcessError, yaml.YAMLError) as error:
        parser.exit(2, f"Error de catálogo o cotización: {error}\n")
    if args.command == "shopping-list" and args.format == "markdown":
        print(shopping_list_markdown(data))
    else:
        json.dump(data, sys.stdout, ensure_ascii=False, indent=2)
        print()


if __name__ == "__main__":
    main()
