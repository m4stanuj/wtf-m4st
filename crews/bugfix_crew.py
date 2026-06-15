import os
import sys
import json
import base64
import datetime
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

# ── Langfuse Tracing (optional) ──────────────────────────────
try:
    import openlit
    langfuse_pk = os.getenv("LANGFUSE_PUBLIC_KEY", "pk-lf-default")
    langfuse_sk = os.getenv("LANGFUSE_SECRET_KEY", "sk-lf-default")
    auth_str = f"{langfuse_pk}:{langfuse_sk}"
    auth_b64 = base64.b64encode(auth_str.encode()).decode()
    openlit.init(
        otlp_endpoint=os.getenv("LANGFUSE_OTEL_ENDPOINT", "http://localhost:3000/api/public/otel"),
        otlp_headers={"Authorization": f"Basic {auth_b64}"}
    )
    print("[trace] OpenLit → Langfuse tracing enabled")
except ImportError:
    print("[trace] openlit not installed. Tracing disabled.")

# ── DRY RUN check ────────────────────────────────────────────
DRY_RUN = "--dry-run" in sys.argv or os.getenv("M4ST_DRY_RUN", "false").lower() == "true"

# ── LLM Setup ────────────────────────────────────────────────
groq_key = os.getenv("GROQ_API_KEY", "")
deepseek_key = os.getenv("DEEPSEEK_API_KEY", "")
ninerouter_url = os.getenv("NINEROUTER_BASE_URL", "http://localhost:20128/v1")
ninerouter_key = os.getenv("NINEROUTER_API_KEY", "")

if DRY_RUN or not ninerouter_key or ninerouter_key in ("your-9router-dashboard-key", "m4st-9router-local-key"):
    print("[llm] Using Groq + DeepSeek directly")
    llm_fast = ChatOpenAI(base_url="https://api.groq.com/openai/v1", api_key=groq_key, model="llama-3.3-70b-versatile")
    llm_deep = ChatOpenAI(base_url="https://api.deepseek.com/v1", api_key=deepseek_key, model="deepseek-chat") if deepseek_key else llm_fast
else:
    print("[llm] Using 9Router")
    llm_fast = ChatOpenAI(base_url=ninerouter_url, api_key=ninerouter_key, model=os.getenv("MODEL_FAST", "groq/llama-3.3-70b-versatile"))
    llm_deep = ChatOpenAI(base_url=ninerouter_url, api_key=ninerouter_key, model=os.getenv("MODEL_DEEP", "deepseek/deepseek-chat"))

# ── Agents ───────────────────────────────────────────────────
analyzer = Agent(
    role="Code Analyzer",
    goal="Read failing test runs, identify code syntax issues or logical errors, and determine root cause.",
    backstory="Expert debugger with deep knowledge of system logs, traces, and code testing architectures.",
    llm=llm_deep,
    verbose=True
)

fixer = Agent(
    role="Fixer",
    goal="Write patch or clean refactoring code for the identified issue.",
    backstory="Quick and clean software developer focused on minimal, correct patches.",
    llm=llm_deep,
    verbose=True
)

tester = Agent(
    role="Tester",
    goal="Verify patches by running unit tests and confirm they pass.",
    backstory="QA automation engineer who validates correctness of new patches.",
    llm=llm_fast,
    verbose=True
)

# ── Tasks ────────────────────────────────────────────────────
if DRY_RUN:
    analyze_desc = "DRY RUN: Simulate analyzing a failed Python test. Report a mock TypeError in a function that expects int but got str."
    fix_desc = "DRY RUN: Simulate writing a patch that adds type checking and conversion. Show an example diff."
    test_desc = "DRY RUN: Simulate running pytest — report 5/5 tests passed after the fix."
else:
    analyze_desc = "Analyze the logs of the latest test run or error reports to identify why a test case or service failed."
    fix_desc = "Based on the analysis, draft a patch or rewrite the faulty code block. Keep changes localized."
    test_desc = "Apply the patch and run pytest suite. If tests still fail, iterate with the fixer."

analyze_task = Task(description=analyze_desc, expected_output="Root cause analysis report.", agent=analyzer)
fix_task = Task(description=fix_desc, expected_output="Code patch or git diff.", agent=fixer)
test_task = Task(description=test_desc, expected_output="Test execution report.", agent=tester)

# ── Crew ─────────────────────────────────────────────────────
bugfix_crew = Crew(
    agents=[analyzer, fixer, tester],
    tasks=[analyze_task, fix_task, test_task],
    process=Process.sequential,
    verbose=True
)

if __name__ == "__main__":
    mode = "DRY RUN" if DRY_RUN else "LIVE"
    print(f"\n🥀 Starting Bug Fix Crew [{mode}]...")
    print(f"   Time: {datetime.datetime.now().isoformat()}")
    
    result = bugfix_crew.kickoff()
    
    # Log
    logs_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "logs")
    os.makedirs(logs_dir, exist_ok=True)
    log_entry = {"timestamp": datetime.datetime.now().isoformat(), "crew": "bugfix", "mode": mode, "result": str(result)[:500]}
    with open(os.path.join(logs_dir, "automation_log.jsonl"), "a") as f:
        f.write(json.dumps(log_entry) + "\n")
    
    print(f"\n--- Bug Fix Crew Complete [{mode}] ---")
    print(result)
