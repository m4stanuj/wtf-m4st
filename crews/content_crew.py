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
ninerouter_url = os.getenv("NINEROUTER_BASE_URL", "http://localhost:20128/v1")
ninerouter_key = os.getenv("NINEROUTER_API_KEY", "")

if DRY_RUN or not ninerouter_key or ninerouter_key in ("your-9router-dashboard-key", "m4st-9router-local-key"):
    print("[llm] Using Groq directly")
    llm_fast = ChatOpenAI(base_url="https://api.groq.com/openai/v1", api_key=groq_key, model="llama-3.3-70b-versatile")
else:
    print("[llm] Using 9Router")
    llm_fast = ChatOpenAI(base_url=ninerouter_url, api_key=ninerouter_key, model=os.getenv("MODEL_FAST", "groq/llama-3.3-70b-versatile"))

# ── Tools ────────────────────────────────────────────────────
tools = []
try:
    from crewai_tools import ExaSearchTool
    exa_key = os.getenv("EXA_API_KEY", "")
    if exa_key and exa_key != "not-configured-yet":
        tools.append(ExaSearchTool())
        print("[tools] Exa Search enabled")
except ImportError:
    pass

# ── Agents ───────────────────────────────────────────────────
researcher = Agent(
    role="Researcher",
    goal="Find recent relevant content and updates on AI trends, cybersecurity, and open-source stacks.",
    backstory="You are an expert researcher who finds concrete technical facts for content creation.",
    tools=tools,
    llm=llm_fast,
    verbose=True
)

writer = Agent(
    role="Writer",
    goal="Draft LinkedIn or Twitter posts from technical research.",
    backstory="You translate raw technical facts into engaging social media posts. Dark terminal aesthetic, ₹0 budget focus.",
    llm=llm_fast,
    verbose=True
)

reviewer = Agent(
    role="Reviewer",
    goal="Check tone vs M4ST SOUL.md guidelines and flag overclaims.",
    backstory="You ensure all claims are honest, sourced, and aligned with Berlin Mode persona.",
    llm=llm_fast,
    verbose=True
)

# ── Tasks ────────────────────────────────────────────────────
if DRY_RUN:
    research_desc = "DRY RUN: Simulate researching AI trends. List 3 example findings about self-hosted LLM stacks, MCP servers, and vector databases."
    write_desc = "DRY RUN: Draft a simulated LinkedIn post about local AI infrastructure. Follow dark terminal aesthetic."
    review_desc = "DRY RUN: Review the draft. Check for overclaims. Output approved/rejected with reasons."
else:
    research_desc = "Research latest technical developments in self-hosted AI, containerized LLM systems, MCP servers, and vector databases."
    write_desc = "Based on research, draft a LinkedIn post and Twitter thread. Dark terminal aesthetic, green-on-black tone, ₹0 budget focus."
    review_desc = "Review drafts against M4ST SOUL.md. Ensure no vanity claims, standalone benchmarks labeled, PC-on scheduled runtime warnings."

research_task = Task(description=research_desc, expected_output="Raw facts, benchmarks, and updates.", agent=researcher)
write_task = Task(description=write_desc, expected_output="Drafted posts for LinkedIn and Twitter.", agent=writer)
review_task = Task(description=review_desc, expected_output="Audited markdown with approved/changed posts.", agent=reviewer)

# ── Crew ─────────────────────────────────────────────────────
content_crew = Crew(
    agents=[researcher, writer, reviewer],
    tasks=[research_task, write_task, review_task],
    process=Process.sequential,
    verbose=True
)

if __name__ == "__main__":
    mode = "DRY RUN" if DRY_RUN else "LIVE"
    print(f"\n🥀 Starting Content Crew [{mode}]...")
    print(f"   Time: {datetime.datetime.now().isoformat()}")
    
    result = content_crew.kickoff()
    
    drafts_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "drafts")
    os.makedirs(drafts_dir, exist_ok=True)
    today_str = datetime.datetime.now().strftime("%Y%m%d")
    output_path = os.path.join(drafts_dir, f"content_{today_str}.md")
    
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(str(result))
    
    # Log
    logs_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "logs")
    os.makedirs(logs_dir, exist_ok=True)
    log_entry = {"timestamp": datetime.datetime.now().isoformat(), "crew": "content", "mode": mode, "output": output_path}
    with open(os.path.join(logs_dir, "automation_log.jsonl"), "a") as f:
        f.write(json.dumps(log_entry) + "\n")
    
    print(f"\n--- Content Crew Complete [{mode}] ---")
    print(f"Draft saved to: {output_path}")
