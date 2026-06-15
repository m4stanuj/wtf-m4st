import os
import json
import subprocess
import httpx
from pathlib import Path
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, Optional, List

app = FastAPI(title="OpenWork MCP Bridge", version="2.0.0", description="M4ST local IDE bridge + dashboard backend")

# ── CORS (for local dashboard dev) ────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Read token from environment
M4ST_TOKEN = os.getenv("M4ST_TOKEN", "default_secret_token")

# Paths
BASE_DIR = Path(__file__).parent.parent  # m4st_project root
LOGS_DIR = BASE_DIR / "logs"
DASHBOARD_DIR = BASE_DIR / "dashboard"

# Dependency to verify token
def verify_token(x_m4st_token: Optional[str] = Header(None)):
    if x_m4st_token != M4ST_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized: Invalid M4ST Token")
    return x_m4st_token

class ExecuteRequest(BaseModel):
    task: str
    context: Optional[Dict[str, Any]] = None

class MemoryQueryRequest(BaseModel):
    query: str
    type: str  # "conversation" or "code"

class AgentRunRequest(BaseModel):
    crew: str
    params: Optional[Dict[str, Any]] = None

class CogneeQueryRequest(BaseModel):
    query: str

class GraphitiWriteRequest(BaseModel):
    content: str
    source: str


# ═══════════════════════════════════════════════════════════════
# HEALTH + SYSTEM ENDPOINTS
# ═══════════════════════════════════════════════════════════════

@app.get("/health")
async def health():
    services = {
        "openclaw": "unknown",
        "ninerouter": "unknown",
        "falkordb": "unknown",
        "graphiti-mcp": "unknown",
        "cognee-mcp": "unknown",
        "langfuse": "unknown",
        "uptime-kuma": "unknown"
    }
    
    async def check_http(url: str) -> str:
        try:
            async with httpx.AsyncClient(timeout=1.0) as client:
                res = await client.get(url)
                return "healthy" if res.status_code < 500 else "unhealthy"
        except Exception:
            return "down"

    services["openclaw"] = await check_http("http://openclaw:3001/")
    services["ninerouter"] = await check_http("http://ninerouter:20128/dashboard")
    services["graphiti-mcp"] = await check_http("http://graphiti-mcp:8001/sse")
    services["cognee-mcp"] = await check_http("http://cognee-mcp:8000/")
    services["langfuse"] = await check_http("http://langfuse:3000/")
    services["uptime-kuma"] = await check_http("http://uptime-kuma:3001/")
    
    # Check falkordb
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1.0)
        s.connect(("falkordb", 6379))
        s.close()
        services["falkordb"] = "healthy"
    except Exception:
        services["falkordb"] = "down"

    is_overall_healthy = all(status == "healthy" or name == "uptime-kuma" for name, status in services.items())
    
    return {
        "status": "healthy" if is_overall_healthy else "degraded",
        "services": services
    }


@app.get("/api/system-info")
async def system_info():
    """Return system metadata for dashboard display."""
    return {
        "version": "v8.2-local",
        "project": "M4ST",
        "author": "@m4stanuj",
        "ram_total_gb": 16,
        "platform": "Windows + Docker Desktop + WSL2",
        "crews": ["nightly_crew", "content_crew", "bugfix_crew"],
        "services_count": 9,
        "budget": "₹0"
    }


@app.get("/api/ram")
async def ram_usage():
    """
    Get Docker RAM usage via 'docker stats'.
    Falls back to estimates if docker command is unavailable.
    """
    try:
        result = subprocess.run(
            ["docker", "stats", "--no-stream", "--format", "{{.Name}}\t{{.MemUsage}}"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            containers = {}
            total_mb = 0
            for line in result.stdout.strip().split("\n"):
                parts = line.split("\t")
                if len(parts) >= 2:
                    name = parts[0]
                    mem_str = parts[1].split("/")[0].strip()
                    # Parse memory (e.g., "512MiB", "1.2GiB")
                    mb = parse_mem_to_mb(mem_str)
                    containers[name] = round(mb, 1)
                    total_mb += mb
            
            return {
                "used_gb": round(total_mb / 1024, 2),
                "total_gb": 16,
                "containers": containers
            }
    except Exception:
        pass
    
    # Fallback estimate
    return {
        "used_gb": 7.2,
        "total_gb": 16,
        "containers": {},
        "estimated": True
    }


def parse_mem_to_mb(mem_str: str) -> float:
    """Parse Docker memory strings like '512MiB', '1.2GiB' to MB."""
    mem_str = mem_str.strip()
    try:
        if "GiB" in mem_str:
            return float(mem_str.replace("GiB", "")) * 1024
        elif "MiB" in mem_str:
            return float(mem_str.replace("MiB", ""))
        elif "KiB" in mem_str:
            return float(mem_str.replace("KiB", "")) / 1024
        elif "GB" in mem_str:
            return float(mem_str.replace("GB", "")) * 1024
        elif "MB" in mem_str:
            return float(mem_str.replace("MB", ""))
        else:
            return float(mem_str)
    except ValueError:
        return 0


# ═══════════════════════════════════════════════════════════════
# LOGS ENDPOINT
# ═══════════════════════════════════════════════════════════════

@app.get("/api/logs")
async def get_logs(limit: int = 25):
    """
    Read recent entries from automation_log.jsonl.
    Returns newest entries up to limit.
    """
    log_path = LOGS_DIR / "automation_log.jsonl"
    
    if not log_path.exists():
        return []
    
    try:
        entries = []
        with open(log_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        entries.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
        
        # Return last N entries
        return entries[-limit:]
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read logs: {str(e)}")


# ═══════════════════════════════════════════════════════════════
# ORIGINAL ENDPOINTS (preserved)
# ═══════════════════════════════════════════════════════════════

@app.post("/execute", dependencies=[Depends(verify_token)])
async def execute(req: ExecuteRequest):
    try:
        # Execute shell command in the container
        process = subprocess.run(
            req.task,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )
        return {
            "stdout": process.stdout,
            "stderr": process.stderr,
            "exit_code": process.returncode
        }
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=408, detail="Command execution timed out")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/memory/query", dependencies=[Depends(verify_token)])
async def memory_query(req: MemoryQueryRequest):
    if req.type == "conversation":
        # Forward query to Graphiti MCP/SSE server
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.post("http://graphiti-mcp:8001/query", json={"query": req.query})
                return res.json()
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Failed to query Graphiti: {str(e)}")
    elif req.type == "code":
        # Forward query to Cognee MCP
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.post("http://cognee-mcp:8000/query", json={"query": req.query})
                return res.json()
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Failed to query Cognee: {str(e)}")
    else:
        raise HTTPException(status_code=400, detail="Invalid memory type. Must be 'conversation' or 'code'.")

@app.post("/agent/run", dependencies=[Depends(verify_token)])
async def agent_run(req: AgentRunRequest):
    # Run the CrewAI scripts under /app/crews/
    crew_path = f"/app/crews/{req.crew}.py"
    if not os.path.exists(crew_path):
        raise HTTPException(status_code=404, detail=f"Crew script {req.crew}.py not found")
    
    try:
        # Build command with optional dry run
        cmd = ["python", crew_path]
        if req.params and req.params.get("dry_run"):
            cmd.append("--dry-run")
        
        # Start the script in the background
        subprocess.Popen(cmd)
        return {"status": "started", "crew": req.crew, "mode": "dry-run" if (req.params and req.params.get("dry_run")) else "live"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to launch crew: {str(e)}")

@app.post("/cognee/query", dependencies=[Depends(verify_token)])
async def cognee_query(req: CogneeQueryRequest):
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            res = await client.post("http://cognee-mcp:8000/query", json={"query": req.query})
            return res.json()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to query Cognee: {str(e)}")

@app.post("/graphiti/write", dependencies=[Depends(verify_token)])
async def graphiti_write(req: GraphitiWriteRequest):
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            res = await client.post("http://graphiti-mcp:8001/write", json={
                "content": req.content,
                "source": req.source
            })
            return res.json()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to write to Graphiti: {str(e)}")


# ═══════════════════════════════════════════════════════════════
# DASHBOARD STATIC FILE SERVING (Vite React build)
# ═══════════════════════════════════════════════════════════════

# Resolve dashboard dist path (Vite builds to dashboard/dist/)
DASHBOARD_DIST = DASHBOARD_DIR / "dist"

# Dashboard route — serves index.html at /dashboard
@app.get("/dashboard", response_class=HTMLResponse)
@app.get("/dashboard/", response_class=HTMLResponse)
async def serve_dashboard():
    """Serve the M4ST Command Center React dashboard."""
    # Try Vite dist first, then fallback to raw dashboard
    for base in [DASHBOARD_DIST, DASHBOARD_DIR]:
        index_path = base / "index.html"
        if index_path.exists():
            return FileResponse(index_path, media_type="text/html")
    return HTMLResponse(
        content="<h1>Dashboard not found</h1><p>Run 'npm run build' in dashboard/ directory.</p>",
        status_code=404
    )

# Mount Vite build assets (CSS, JS chunks)
if DASHBOARD_DIST.exists():
    app.mount("/dashboard", StaticFiles(directory=str(DASHBOARD_DIST)), name="dashboard-static")
elif DASHBOARD_DIR.exists():
    app.mount("/dashboard", StaticFiles(directory=str(DASHBOARD_DIR)), name="dashboard-static")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8765)
