from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {".md", ".py", ".js", ".jsx", ".css", ".yml", ".yaml", ".toml", ".json"}
MOJIBAKE_MARKERS = (
    "\u00e2\u20ac",
    "\u00e2\u20ac\u2122",
    "\u00e2\u20ac\u0153",
    "\u00f0\u0178",
    "\u00c2\u00b7",
    "\u00c2\u00a9",
    "\u00c2\u00ae",
)
SKIP_DIRS = {".git", "node_modules", "dist", ".venv", "venv"}


def iter_text_files():
    for path in ROOT.rglob("*"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.is_file() and path.suffix in TEXT_SUFFIXES:
            yield path


def main():
    failures = []
    for path in iter_text_files():
        rel = path.relative_to(ROOT)
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            failures.append(f"{rel}: not valid UTF-8 ({exc})")
            continue
        for marker in MOJIBAKE_MARKERS:
            if marker in text:
                failures.append(f"{rel}: possible mojibake marker {marker!r}")
                break

    if failures:
        print("\n".join(failures))
        sys.exit(1)


if __name__ == "__main__":
    main()
