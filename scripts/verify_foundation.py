import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSECURE_TOKENS = {"", "default_secret_token", "change-this-to-a-strong-random-token"}


def check(name, ok, detail=""):
    status = "OK" if ok else "FAIL"
    print(f"[{status}] {name}{': ' + detail if detail else ''}")
    return ok


def run(cmd, cwd=ROOT):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=60)


def main():
    checks = []
    token = os.getenv("M4ST_TOKEN", "")
    admin_tokens = os.getenv("M4ST_ADMIN_TOKENS", "")
    read_tokens = os.getenv("M4ST_READ_TOKENS", "")

    checks.append(check(
        "OpenWork admin token configured",
        bool((set(token.split(",")) | set(admin_tokens.split(","))) - INSECURE_TOKENS),
        "set M4ST_TOKEN or M4ST_ADMIN_TOKENS",
    ))
    checks.append(check(
        "OpenWork read token configured",
        bool((set(read_tokens.split(",")) | set(token.split(",")) | set(admin_tokens.split(","))) - INSECURE_TOKENS),
        "set M4ST_READ_TOKENS or reuse admin token locally",
    ))

    for path in ["crews", "dashboard", "openwork-mcp", "docker-compose.yml", "docker/docker-compose.yml"]:
        checks.append(check(f"Required path exists: {path}", (ROOT / path).exists()))

    checks.append(check("Docker CLI available", shutil.which("docker") is not None))
    if shutil.which("docker"):
        root_compose = run(["docker", "compose", "-f", "docker-compose.yml", "config"])
        checks.append(check("Root compose validates", root_compose.returncode == 0, root_compose.stderr.strip()[:200]))
        full_compose = run(["docker", "compose", "-f", "docker/docker-compose.yml", "config"])
        checks.append(check("Full compose validates", full_compose.returncode == 0, full_compose.stderr.strip()[:200]))

    if shutil.which("npm"):
        npm_ci_ready = (ROOT / "dashboard" / "package-lock.json").exists()
        checks.append(check("Dashboard lockfile exists", npm_ci_ready))

    if not all(checks):
        sys.exit(1)


if __name__ == "__main__":
    main()
