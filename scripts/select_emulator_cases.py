#!/usr/bin/env python3
"""Select AWS Emulator cases from the Terraform changes in a Git comparison."""

import argparse
import json
import re
import subprocess
from pathlib import Path

import hcl2


ROOT = Path(__file__).resolve().parent.parent
SHARED = {
    ".github/workflows/validate.yml",
    "scripts/validate.sh",
    "scripts/security.sh",
    "scripts/select_emulator_cases.py",
    "scripts/test_emulator.py",
    "scripts/requirements-baseline.txt",
}
REPRESENTATIVE = {"s3/default", "dynamodb/on-demand"}
REPO_SOURCE = re.compile(
    r"^git::(?:https://github\.com/|ssh://git@github\.com/|git@github\.com:)"
    r"marcor0311/aws-cloud-consultant-baseline-modules(?:\.git)?//aws/([^/?]+)(?:[/?.].*)?$"
)


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True)


def git_changes(root, base):
    sha = git(root, "rev-parse", "--verify", "--end-of-options", f"{base}^{{commit}}").strip()
    status_and_paths = git(root, "diff", "--name-status", "--no-renames", "-z", f"{sha}...HEAD", "--")
    items = iter(status_and_paths.split("\0")[:-1])
    return list(zip(items, items, strict=True))


def terraform_source_file(path):
    return path.name.endswith((".tf", ".tf.json"))


def source_module(root, path, source):
    if source.startswith(("../", "./")):
        local = (path.parent / source).resolve()
        if local.is_relative_to(root):
            parts = local.relative_to(root).parts
            if len(parts) >= 2 and parts[0] == "aws":
                return parts[1]
    match = REPO_SOURCE.match(source)
    if match:
        ref = re.search(r"[?&]ref=([^&]+)", source)
        if not ref or not re.fullmatch(r"[0-9a-fA-F]{40}", ref[1]):
            return match[1]
    return None


def dependencies(root, path):
    with path.open(encoding="utf-8") as config:
        blocks = json.load(config) if path.name.endswith(".tf.json") else hcl2.load(config)
    calls = blocks.get("module", [])
    if isinstance(calls, dict):
        calls = [calls]
    for block in calls:
        for attributes in block.values():
            source = source_module(root, path, attributes["source"])
            if source:
                yield source


def relevant(path):
    return (
        path.endswith((".tf", ".tf.json", ".tftest.hcl", ".tftest.json", ".tfvars.example"))
        or Path(path).name in {"module.yaml", ".terraform.lock.hcl"}
    )


def select(root, changes, full=False):
    root = root.resolve()
    files = [
        root / file for file in git(root, "ls-files", "-z").split("\0")
        if file and (root / file).is_file()
    ]
    modules = {
        path.parent.name for path in files
        if path.name == "module.yaml" and path.parent.parent == root / "aws"
    }
    retired = {
        Path(path).parts[1] for status, path in changes
        if status == "D" and re.fullmatch(r"aws/[^/]+/module\.yaml", path)
    } - modules
    selected_modules = set()
    selected_examples = set()
    changed_example_paths = set()
    shared = False
    for _, path in changes:
        parts = Path(path).parts
        shared |= path in SHARED or path.startswith("scripts/emulator/")
        if len(parts) < 3:
            continue
        if parts[0] == "examples" and not path.endswith(".md"):
            changed_example_paths.add("/".join(parts[:2]))
        if parts[0] != "aws" or parts[1] not in modules:
            continue
        if len(parts) >= 5 and parts[2] == "examples" and not path.endswith(".md"):
            selected_examples.add(f"{parts[1]}/{parts[3]}")
        elif relevant(path):
            selected_modules.add(parts[1])

    module_cases = set()
    examples = {}
    stale = set()
    for path in files:
        if not terraform_source_file(path):
            continue
        parts = path.relative_to(root).parts
        sources = set(dependencies(root, path))
        stale.update(f"{path.relative_to(root)} → {module}" for module in sources & retired)
        if len(parts) >= 5 and parts[0] == "aws" and parts[1] in modules and parts[2] == "examples":
            case = f"{parts[1]}/{parts[3]}"
            module_cases.add(case)
            examples.setdefault(case, set()).update(sources)
        if len(parts) >= 3 and parts[0] == "examples":
            case = "example:" + "/".join(parts[:2])
            examples.setdefault(case, set()).update(sources)

    if stale:
        raise ValueError("Referencias activas a módulos retirados: " + ", ".join(sorted(stale)))
    examples = {case: sources for case, sources in examples.items() if sources <= modules}
    if full:
        return {"modules": sorted(modules), "cases": sorted(examples), "retired": sorted(retired)}
    cases = set(REPRESENTATIVE & module_cases) if shared else set()
    for case, sources in examples.items():
        if case in module_cases:
            if case in selected_examples or case.split("/")[0] in selected_modules or sources & selected_modules:
                cases.add(case)
        elif sources & selected_modules or case.removeprefix("example:") in changed_example_paths:
            cases.add(case)
    selected_modules.update(case.split("/")[0] for case in cases & module_cases)
    return {"modules": sorted(selected_modules), "cases": sorted(cases), "retired": sorted(retired)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--base")
    mode.add_argument("--all", action="store_true")
    args = parser.parse_args()
    try:
        print(json.dumps(select(ROOT, git_changes(ROOT, args.base) if args.base else [], args.all)))
    except (subprocess.CalledProcessError, ValueError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
