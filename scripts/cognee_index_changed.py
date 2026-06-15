#!/usr/bin/env python3
"""
cognee_index_changed.py — git post-commit hook se call hota hai
Changed files ko Cognee knowledge graph mein index karta hai
Usage: python cognee_index_changed.py file1.py file2.md ...
"""
import sys
import asyncio
import os
from pathlib import Path

M4ST_HOME = Path("/home/anuj/m4st")

async def index_files(files: list[str]):
    try:
        import cognee
        from dotenv import load_dotenv
        load_dotenv(M4ST_HOME / ".env")

        valid_files = [f for f in files if Path(f).exists() and not f.startswith(".")]
        if not valid_files:
            print("[cognee-hook] No indexable files found.")
            return

        print(f"[cognee-hook] Indexing {len(valid_files)} changed file(s)...")
        for f in valid_files:
            try:
                await cognee.add(f)
                print(f"[cognee-hook] Indexed: {f}")
            except Exception as e:
                print(f"[cognee-hook] Skip {f}: {e}")

        await cognee.make()
        print("[cognee-hook] Knowledge graph updated.")

    except ImportError:
        print("[cognee-hook] cognee not installed — skipping index.")
    except Exception as e:
        print(f"[cognee-hook] Error: {e}")

if __name__ == "__main__":
    changed = sys.argv[1:]
    if not changed:
        print("[cognee-hook] No files passed. Usage: python cognee_index_changed.py file1 file2 ...")
        sys.exit(0)
    asyncio.run(index_files(changed))
