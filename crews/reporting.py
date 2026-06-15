import datetime
import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
LOGS_DIR = PROJECT_ROOT / "logs"
REPORTS_DIR = PROJECT_ROOT / "reports"


def write_crew_outputs(crew: str, mode: str, result, extra: dict | None = None) -> dict:
    timestamp = datetime.datetime.now(datetime.timezone.utc)
    day_dir = REPORTS_DIR / timestamp.strftime("%Y-%m-%d")
    day_dir.mkdir(parents=True, exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    result_text = str(result)
    report_path = day_dir / f"{timestamp.strftime('%H%M%S')}_{crew}.md"
    report_path.write_text(
        "\n".join([
            f"# {crew.title()} Crew Report",
            "",
            f"- Timestamp: {timestamp.isoformat()}",
            f"- Mode: {mode}",
            "",
            "## Result",
            "",
            result_text,
            "",
        ]),
        encoding="utf-8",
    )

    log_entry = {
        "timestamp": timestamp.isoformat(),
        "crew": crew,
        "mode": mode,
        "result": result_text[:1000],
        "report": str(report_path.relative_to(PROJECT_ROOT)),
    }
    if extra:
        log_entry.update(extra)

    with (LOGS_DIR / "automation_log.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")

    return log_entry
