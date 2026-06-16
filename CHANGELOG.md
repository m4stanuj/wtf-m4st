# Changelog

All notable changes to the WTF M4ST project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [8.2.1] - 2026-06-16

### Added
- Created `pyproject.toml` to define dependencies and optional dev dependencies (`pytest`, `ruff`, etc.).
- Created `.pre-commit-config.yaml` with gitleaks, ruff lint/format, and pre-commit-hooks checks.
- Created `SECURITY.md` outlining the responsible disclosure guidelines and pentesting scope.
- Created `CONTRIBUTING.md` setting up standard contribution steps and coding guidelines.
- Created `.dockerignore` to filter build context, preventing secret leakages.
- Added `scripts/validate_env.py` to check model provider configuration at startup.
- Added `scripts/run_all_crews.py` to run crews sequentially, preventing OOM issues.
- Added healthchecks and dependencies (`depends_on` healthy conditions) to all services in the Docker compose system.
- Added LibreChat and Perplexica services directly to the root `docker-compose.yml`.
- Added Ollama service in `docker-compose.yml` under the `offline` profile.
- Added `scripts/check_startup.sh` diagnostic script to poll HTTP health endpoints for all services.
- Created a GitHub Actions CI pipeline in `.github/workflows/ci.yml`.

### Changed
- Moved SEPCC proxy credentials out of `.env.example` into a private `docs/SEPCC_SETUP.md`.
- Fixed the default `GITHUB_REPO` to point to the correct repo `m4stanuj/wtf-m4st` in `.env.example`.
- Mapped FalkorDB host port to `6380` to prevent port conflicts with default local Redis.
- Hardened token validation in `openwork-mcp/main.py` to prevent empty header bypasses.
- Implemented command validation allowlist checks in the `/execute` shell endpoint.
- Pin all docker images in `docker-compose.yml` to stable major versions or specific tags instead of `:latest`.
- Configured Postgres + Clickhouse dependencies and correct environment variables for Langfuse v3.
- Standardized service counts in `README.md` to 15 core services.
- Removed fake Crawl4AI CVE reference and linked to GitHub Security Advisory.
