import os
import sys

# Try loading .env
try:
    from dotenv import load_dotenv
    load_dotenv()
    print("[env] Loaded .env file successfully.")
except ImportError:
    # Try importing manually
    if os.path.exists(".env"):
        print("[env] dotenv module not installed, reading .env manually...")
        with open(".env") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    parts = line.split("=", 1)
                    if len(parts) == 2:
                        os.environ[parts[0].strip()] = parts[1].strip()

# Verification flags
has_errors = False
has_warnings = False

def check_key(key_name, required=True):
    val = os.getenv(key_name, "").strip()
    if not val or val.startswith("your-") or val.startswith("change-"):
        if required:
            print(f"\033[91m[ERROR] {key_name} is missing or has a default/placeholder value!\033[0m")
            return False
        else:
            print(f"\033[93m[WARNING] {key_name} is not set. Some optional features may fail.\033[0m")
            return False
    return True

print("\n--- Validating M4ST Environment Configuration ---")

# 1. Check core bridge keys
if not check_key("M4ST_TOKEN", required=True):
    has_errors = True

# 2. Check models and corresponding provider keys
models = {
    "MODEL_FAST": os.getenv("MODEL_FAST", ""),
    "MODEL_DEEP": os.getenv("MODEL_DEEP", ""),
    "MODEL_REASONING": os.getenv("MODEL_REASONING", "")
}

for env_var, model_name in models.items():
    if not model_name:
        print(f"\033[93m[WARNING] {env_var} is not configured.\033[0m")
        has_warnings = True
        continue
    
    print(f"[info] Checking provider key for {env_var}='{model_name}'...")
    
    # Analyze provider prefix
    if "/" in model_name:
        provider = model_name.split("/")[0].lower()
    else:
        provider = model_name.lower()
        
    if provider == "groq":
        if not check_key("GROQ_API_KEY", required=True):
            has_errors = True
    elif provider == "deepseek":
        if not check_key("DEEPSEEK_API_KEY", required=True):
            has_errors = True
    elif provider in ("gemini", "google", "opencode"):
        if not check_key("GEMINI_API_KEY", required=True):
            has_errors = True
    elif provider == "nvidia":
        if not check_key("NVIDIA_NIM_API_KEY", required=True):
            has_errors = True
    elif provider == "ollama":
        print("[info] Ollama selected. Offline local inference will be used.")
    else:
        print(f"\033[93m[WARNING] Unknown model provider '{provider}'. Ensure API key is configured.\033[0m")
        has_warnings = True

# 3. Check specific key relations
# Graphiti specifically needs GOOGLE_API_KEY
google_key = os.getenv("GOOGLE_API_KEY", "").strip()
gemini_key = os.getenv("GEMINI_API_KEY", "").strip()
if gemini_key and (not google_key or google_key.startswith("your-")):
    print("\033[93m[WARNING] GEMINI_API_KEY is configured but GOOGLE_API_KEY is missing or placeholder. Graphiti embeddings will fail! Copy GEMINI_API_KEY into GOOGLE_API_KEY.\033[0m")
    has_warnings = True

# 4. Check 9Router integration
ninerouter_key = os.getenv("NINEROUTER_API_KEY", "").strip()
if not ninerouter_key or ninerouter_key in ("your-9router-dashboard-key", "m4st-9router-local-key"):
    print("\033[93m[WARNING] NINEROUTER_API_KEY is not configured or using default. Crews will fall back to direct OpenAI/Groq/Deepseek calls.\033[0m")
    has_warnings = True

print("-------------------------------------------------")
if has_errors:
    print("\033[91mStatus: CONFIGURATION ERRORS DETECTED. Please fix the red items above before running crews.\033[0m")
    sys.exit(1)
elif has_warnings:
    print("\033[93mStatus: CONFIGURATION WARNINGS DETECTED. Stack will run but some tools/features may fail.\033[0m")
    sys.exit(0)
else:
    print("\033[92mStatus: ALL ENVIRONMENT VARIABLES VERIFIED AND CORRECT.\033[0m")
    sys.exit(0)
