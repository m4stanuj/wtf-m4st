#!/usr/bin/env python3
"""
nightly_telegram_report.py — 7 AM mein run hota hai
Langfuse stats + Uptime Kuma health ko Telegram pe bhejta hai
"""
import os, asyncio, httpx
from datetime import datetime, timedelta
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path("/home/anuj/m4st/.env"))

BOT_TOKEN   = os.getenv("TELEGRAM_BOT_TOKEN", "")
CHAT_ID     = os.getenv("TELEGRAM_CHAT_ID", "")
LANGFUSE_URL = os.getenv("LANGFUSE_BASEURL", "http://localhost:3000")
LANGFUSE_PK  = os.getenv("LANGFUSE_PUBLIC_KEY", "")
LANGFUSE_SK  = os.getenv("LANGFUSE_SECRET_KEY", "")


async def get_langfuse_stats() -> dict:
    """Fetch last 24h trace count and cost from Langfuse."""
    try:
        import base64
        auth = base64.b64encode(f"{LANGFUSE_PK}:{LANGFUSE_SK}".encode()).decode()
        since = (datetime.utcnow() - timedelta(hours=24)).isoformat() + "Z"

        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(
                f"{LANGFUSE_URL}/api/public/traces",
                headers={"Authorization": f"Basic {auth}"},
                params={"fromTimestamp": since, "limit": 1}
            )
            if r.status_code == 200:
                data = r.json()
                return {"traces": data.get("meta", {}).get("totalItems", "?"), "status": "ok"}
    except Exception as e:
        pass
    return {"traces": "N/A", "status": "error"}


async def get_service_health() -> dict:
    """Check all M4ST services."""
    services = {
        "OpenClaw":     "http://localhost:3001/api/status",
        "9Router":      "http://localhost:20128/dashboard",
        "Graphiti MCP": "http://localhost:8001/sse",
        "Cognee MCP":   "http://localhost:8000/",
        "Langfuse":     "http://localhost:3000/",
        "Uptime Kuma":  "http://localhost:3002/",
        "OpenWork MCP": "http://localhost:8765/health",
        "SEPCC":        "http://localhost:8082/",
    }
    results = {}
    async with httpx.AsyncClient(timeout=2) as client:
        for name, url in services.items():
            try:
                r = await client.get(url)
                results[name] = "✅" if r.status_code < 500 else "⚠️"
            except Exception:
                results[name] = "❌"
    return results


async def send_telegram(text: str):
    if not BOT_TOKEN or not CHAT_ID:
        print("[telegram] BOT_TOKEN or CHAT_ID not set — skipping.")
        return
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(url, json={
            "chat_id": CHAT_ID,
            "text": text,
            "parse_mode": "Markdown"
        })
        if r.status_code == 200:
            print("[telegram] Report sent ✅")
        else:
            print(f"[telegram] Error: {r.status_code} — {r.text}")


async def main():
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    print(f"[nightly-report] Generating report for {now}...")

    health  = await get_service_health()
    langfuse = await get_langfuse_stats()

    # Build message
    health_lines = "\n".join(f"  {s}: {h}" for s, h in health.items())
    all_healthy  = all(v == "✅" for v in health.values())
    status_emoji = "🟢" if all_healthy else "🔴"

    msg = f"""*M4ST Nightly Report* — {now}

{status_emoji} *Service Health*
{health_lines}

📊 *Langfuse (last 24h)*
  Traces: {langfuse['traces']}

🕐 *Autonomous Window*: 11 PM – 7 AM complete
🥀 @m4stanuj · v8.2-local"""

    print(msg)
    await send_telegram(msg)


if __name__ == "__main__":
    asyncio.run(main())
