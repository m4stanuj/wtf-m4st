#!/bin/bash
# M4ST Startup Order & Health Validation Script

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${CYAN}==================================================${RESET}"
echo -e "${CYAN}        M4ST Service Startup Validation           ${RESET}"
echo -e "${CYAN}==================================================${RESET}"

check_service() {
    local name=$1
    local url=$2
    local expected_code=$3
    
    echo -n "Checking $name... "
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url")
    
    if [ "$response" -eq "$expected_code" ] || { [ "$expected_code" -eq 200 ] && [ "$response" -ge 200 ] && [ "$response" -lt 400 ]; }; then
        echo -e "${GREEN}[PASS] (HTTP $response)${RESET}"
        return 0
    else
        echo -e "${RED}[FAIL] (HTTP $response, expected $expected_code)${RESET}"
        return 1
    fi
}

check_port() {
    local name=$1
    local port=$2
    
    echo -n "Checking port $name ($port)... "
    if (echo >/dev/tcp/localhost/"$port") &>/dev/null; then
        echo -e "${GREEN}[PASS] (TCP connection established)${RESET}"
        return 0
    else
        echo -e "${RED}[FAIL] (Connection refused)${RESET}"
        return 1
    fi
}

degraded=0

# 1. 9Router
check_service "9Router" "http://localhost:20128/dashboard" 200 || degraded=1

# 2. FalkorDB (mapped to host 6380)
check_port "FalkorDB" "6380" || degraded=1

# 3. Graphiti MCP
check_service "Graphiti MCP" "http://localhost:8001/" 200 || degraded=1

# 4. Cognee MCP
check_service "Cognee MCP" "http://localhost:8000/" 200 || degraded=1

# 5. Langfuse
check_service "Langfuse" "http://localhost:3000/" 200 || degraded=1

# 6. Uptime Kuma
check_service "Uptime Kuma" "http://localhost:3002/" 200 || degraded=1

# 7. OpenWork MCP
check_service "OpenWork MCP (Health)" "http://localhost:8765/health" 200 || degraded=1

# 8. OpenClaw
check_port "OpenClaw" "3001" || degraded=1

# 9. SEPCC
check_port "SEPCC proxy" "8082" || degraded=1

# 10. Perplexica
check_service "Perplexica Search" "http://localhost:3010/" 200 || degraded=1

# 11. LibreChat
check_service "LibreChat UI" "http://localhost:3080/" 200 || degraded=1

# 12. Ollama (optional profile)
if (echo >/dev/tcp/localhost/11434) &>/dev/null; then
    check_service "Ollama" "http://localhost:11434/" 200 || echo -e "${YELLOW}[INFO] Ollama profile offline/inactive${RESET}"
fi

echo -e "${CYAN}--------------------------------------------------${RESET}"

if [ $degraded -eq 1 ]; then
    echo -e "${RED}Status: DEGRADED. Check logs with 'docker compose logs <service>'.${RESET}"
    exit 1
else
    echo -e "${GREEN}Status: ALL CORE SERVICES RUNNING AND RESPONDING.${RESET}"
    exit 0
fi
