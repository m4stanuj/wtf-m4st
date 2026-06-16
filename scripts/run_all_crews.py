import os
import sys
import subprocess
import time

# Check if dry run is passed to parent script
dry_run = "--dry-run" in sys.argv

scripts = [
    ("Nightly Crew", "crews/nightly_crew.py"),
    ("Content Crew", "crews/content_crew.py"),
    ("Cognee Reindex", "scripts/cognee_full_reindex.py"),
    ("Bugfix Crew", "crews/bugfix_crew.py"),
    ("Morning Report", "scripts/nightly_telegram_report.py")
]

print(f"\n==================================================")
print(f"       M4ST Chained Crew Sequential Runner        ")
print(f"==================================================")
if dry_run:
    print("[runner] Mode: DRY RUN (passing --dry-run to subscripts)")
else:
    print("[runner] Mode: LIVE")

# Resolve working directory to the repo root
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(BASE_DIR)

# Resolve python executable to use (check for local virtual environment)
venv_python = None
if sys.platform == "win32":
    win_py = os.path.join(BASE_DIR, ".venv", "Scripts", "python.exe")
    if os.path.exists(win_py):
        venv_python = win_py
else:
    nix_py = os.path.join(BASE_DIR, ".venv", "bin", "python")
    if os.path.exists(nix_py):
        venv_python = nix_py

python_exe = venv_python if venv_python else sys.executable
print(f"[runner] Using Python executable: {python_exe}")

for name, script_path in scripts:
    full_path = os.path.join(BASE_DIR, script_path)
    if not os.path.exists(full_path):
        print(f"\033[93m[runner] Warning: Script {script_path} not found. Skipping.\033[0m")
        continue

    print(f"\n[runner] --- Starting {name} ({script_path}) ---")
    
    # Construct subprocess command
    cmd = [python_exe, full_path]
    # Pass dry run flag to CrewAI scripts
    if dry_run and "crew" in script_path:
        cmd.append("--dry-run")
        
    start_time = time.time()
    try:
        # Run process and wait for completion
        # Direct stdout and stderr to parent console
        result = subprocess.run(cmd, stdout=sys.stdout, stderr=sys.stderr, check=False)
        duration = time.time() - start_time
        
        if result.returncode == 0:
            print(f"\033[92m[runner] Success: {name} completed in {duration:.1f}s\033[0m")
        else:
            print(f"\033[91m[runner] Failure: {name} exited with code {result.returncode} in {duration:.1f}s\033[0m")
    except Exception as e:
        print(f"\033[91m[runner] Error executing {name}: {str(e)}\033[0m")
        
    # Cool down period to prevent CPU/Memory spikes
    time.sleep(2)

print(f"\n==================================================")
print(f"      All Scheduled Crews Sequential Runs Ended   ")
print(f"==================================================")
