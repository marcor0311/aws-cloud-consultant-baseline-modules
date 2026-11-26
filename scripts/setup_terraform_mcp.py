#!/usr/bin/env python3
"""Install the pinned Terraform Registry MCP server in this repository."""

import argparse
import hashlib
import os
import platform
import shutil
from pathlib import Path
from tempfile import TemporaryDirectory
from urllib.request import urlopen
from zipfile import ZipFile


VERSION = "1.4.1"
RELEASE = f"https://releases.hashicorp.com/terraform-mcp-server/{VERSION}"
PLATFORMS = {
    ("Darwin", "arm64"): ("darwin_arm64", "10e6d49e8437b4099d2d4435d87b95c6896a98ec4ba140bdaa48d0aaadc17f1b"),
    ("Linux", "x86_64"): ("linux_amd64", "8b2526451162e16d803ab014f7070f0f412962cdffffdcf446e70a846362481b"),
}


def install(archive=None):
    target = PLATFORMS.get((platform.system(), platform.machine()))
    if target is None:
        raise ValueError("Esta instalación admite macOS arm64 y Linux amd64.")
    suffix, expected = target
    tools_directory = Path(__file__).resolve().parent.parent / ".tools"
    tools_directory.mkdir(exist_ok=True)
    executable = tools_directory / "terraform-mcp-server"

    with TemporaryDirectory(dir=tools_directory) as temporary:
        staging = Path(temporary)
        if archive is None:
            archive = staging / "release.zip"
            url = f"{RELEASE}/terraform-mcp-server_{VERSION}_{suffix}.zip"
            with urlopen(url, timeout=60) as response, archive.open("wb") as package:
                shutil.copyfileobj(response, package)

        with archive.open("rb") as package:
            digest = hashlib.file_digest(package, "sha256").hexdigest()
        if digest != expected:
            raise ValueError("El SHA-256 del archivo no coincide con el release oficial fijado.")

        staged_binary = staging / executable.name
        with ZipFile(archive) as package, package.open(executable.name) as binary, staged_binary.open("wb") as output:
            shutil.copyfileobj(binary, output)
        staged_binary.chmod(0o755)
        os.replace(staged_binary, executable)
    return executable


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, help="Usar un ZIP oficial ya descargado y verificar su SHA-256")
    args = parser.parse_args()
    try:
        executable = install(args.archive)
    except (OSError, ValueError) as error:
        parser.exit(2, f"No se pudo instalar Terraform MCP: {error}\n")
    print(executable)


if __name__ == "__main__":
    main()
