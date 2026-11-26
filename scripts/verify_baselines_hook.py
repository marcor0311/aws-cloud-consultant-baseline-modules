"""Run local module checks before Codex finishes a turn with baseline changes."""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def verify():
    try:
        base = git("merge-base", "HEAD", "main").strip().decode()
    except subprocess.CalledProcessError:
        base = "HEAD"
    tracked = git("diff", "--name-only", "-z", base, "--", "aws/")
    staged = git("diff", "--cached", "--name-only", "-z", "--", "aws/")
    untracked = git("ls-files", "--others", "--exclude-standard", "-z", "--", "aws/")
    if not (tracked or staged or untracked):
        return None

    report = ROOT / "reports" / "baseline-verifier.log"
    report.parent.mkdir(exist_ok=True)
    failures = []
    with report.open("w", encoding="utf-8") as log:
        for script in ("scripts/validate.sh", "scripts/security.sh"):
            print(f"\n$ {script}", file=log, flush=True)
            result = subprocess.run(["bash", script], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
            if result.returncode:
                failures.append(f"{script} (código {result.returncode})")
    return failures


def main():
    event = json.load(sys.stdin)
    try:
        failures = verify()
    except (OSError, subprocess.CalledProcessError) as error:
        failures = [str(error)]
    if failures is None:
        return
    if failures:
        message = "Verificación de baselines pendiente: " + ", ".join(failures)
        message += ". Consulta reports/baseline-verifier.log si se generó y reporta el fallo."
        if event.get("stop_hook_active"):
            print(json.dumps({"systemMessage": message}))
        else:
            print(json.dumps({"decision": "block", "reason": message}))
    else:
        print(json.dumps({"systemMessage": "Verificación de baselines aprobada. Evidencia en reports/baseline-verifier.log."}))


if __name__ == "__main__":
    main()
