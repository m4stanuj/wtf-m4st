import os
import sys
import json
import datetime
import base64
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI
from reporting import write_crew_outputs

# ── Langfuse Tracing (optional — graceful fallback) ──────────
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
    print("[trace] openlit not installed. Tracing disabled (OK for dry run).")

# ── DRY RUN check ────────────────────────────────────────────
DRY_RUN = "--dry-run" in sys.argv or os.getenv("M4ST_DRY_RUN", "false").lower() == "true"

# ── LLM Setup — Try 9Router first, fallback to direct Groq ──
ninerouter_url = os.getenv("NINEROUTER_BASE_URL", "http://localhost:20128/v1")
ninerouter_key = os.getenv("NINEROUTER_API_KEY", "m4st-9router-local-key")
groq_key = os.getenv("GROQ_API_KEY", "")

# For dry run or if 9Router isn't configured, use Groq directly
if DRY_RUN or not ninerouter_key or ninerouter_key == "your-9router-dashboard-key":
    print("[llm] Using Groq directly (dry run / 9Router not configured)")
    llm_fast = ChatOpenAI(
        base_url="https://api.groq.com/openai/v1",
        api_key=groq_key,
        model="llama-3.3-70b-versatile"
    )
    llm_deep = llm_fast  # Use same model for dry run
else:
    print("[llm] Using 9Router for LLM routing")
    llm_fast = ChatOpenAI(
        base_url=ninerouter_url,
        api_key=ninerouter_key,
        model=os.getenv("MODEL_FAST", "groq/llama-3.3-70b-versatile")
    )
    llm_deep = ChatOpenAI(
        base_url=ninerouter_url,
        api_key=ninerouter_key,
        model=os.getenv("MODEL_DEEP", "deepseek/deepseek-chat")
    )

# ── Agents ───────────────────────────────────────────────────
scanner = Agent(
    role="GitHub Scanner",
    goal="Scan repos for issues, PRs, and dependency alerts.",
    backstory="You are a meticulous security scanner that monitors repos for changes, issues, and security vulnerabilities.",
    llm=llm_fast,
    verbose=True
)

drafter = Agent(
    role="Content Drafter",
    goal="Draft social content from scan results.",
    backstory="You are a technical writer who communicates repo changes, updates, and highlights into high-impact social media drafts.",
    llm=llm_fast,
    verbose=True
)

fixer = Agent(
    role="Bug Fixer",
    goal="Attempt automated fix on flagged issues.",
    backstory="You are an expert software engineer specializing in quickly patching security vulnerabilities and bugs.",
    llm=llm_deep,
    verbose=True
)

reporter = Agent(
    role="Reporter",
    goal="Compile Telegram report — concise.",
    backstory="You are a operations reporter that summarizes system logs and crew activities into bite-sized, readable status updates.",
    llm=llm_fast,
    verbose=True
)

# ── Tasks ────────────────────────────────────────────────────
if DRY_RUN:
    scan_desc = "This is a DRY RUN. Simulate scanning a GitHub repo by listing 3 example issues you would typically find: one security advisory, one stale PR, one dependency update. Format as a structured list."
    draft_desc = "This is a DRY RUN. Based on the simulated scan results, draft a short example LinkedIn post about a project maintaining strong security hygiene."
    fix_desc = "This is a DRY RUN. Simulate suggesting a dependency bump patch from an older package version to a newer one. Show an example diff."
    report_desc = "This is a DRY RUN. Generate a simulated Telegram-style status report with emojis summarizing: scanned 1 repo, found 3 issues, drafted 1 post, suggested 1 fix."
else:
    scan_desc = "Scan the local codebase and configured GitHub repos to identify open issues, pending PRs, and package dependencies that need updates."
    draft_desc = "Use the scan results to draft a technical post summarizing the current status of the project, highlighting any updates or fixes."
    fix_desc = "Analyze the highest priority issue from the scan results and draft a patch or suggest a code change to resolve it."
    report_desc = "Consolidate results from the scanning, drafting, and fixing tasks into a concise Markdown report for Telegram notification."

scan_task = Task(
    description=scan_desc,
    expected_output="A list of identified issues, PRs, and dependency warnings.",
    agent=scanner
)

draft_task = Task(
    description=draft_desc,
    expected_output="A drafted markdown post suited for LinkedIn/Twitter.",
    agent=drafter
)

fix_task = Task(
    description=fix_desc,
    expected_output="A bugfix patch suggestion or completed code modifications.",
    agent=fixer
)

report_task = Task(
    description=report_desc,
    expected_output="A concise Markdown status report suitable for a Telegram notification.",
    agent=reporter
)

# ── Crew ─────────────────────────────────────────────────────
nightly_crew = Crew(
    agents=[scanner, drafter, fixer, reporter],
    tasks=[scan_task, draft_task, fix_task, report_task],
    process=Process.sequential,
    verbose=True
)

if __name__ == "__main__":
    mode = "DRY RUN" if DRY_RUN else "LIVE"
    print(f"\n🥀 Starting Nightly Crew [{mode}]...")
    print(f"   Time: {datetime.datetime.now().isoformat()}")
    print(f"   LLM: {'Groq Direct' if DRY_RUN else '9Router'}")
    print()
    
    result = nightly_crew.kickoff()
    
    log_entry = write_crew_outputs("nightly", mode, result)
    
    print(f"\n--- Nightly Crew Complete [{mode}] ---")
    print(f"Report saved to: {log_entry['report']}")
    print(result)
