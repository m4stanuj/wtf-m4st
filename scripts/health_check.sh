#!/bin/bash
# M4ST Local Health Check Script (WSL2 / Linux)

echo -e "\e[32m=====================================\e[0m"
echo -e "\e[32m   M4ST local stack health check\e[0m"
echo -e "\e[32m=====================================\e[0m"

declare -A services=(
    ["OpenClaw"]="3001"
    ["9Router"]="20128"
    ["FalkorDB"]="6379"
    ["Graphiti MCP"]="8001"
    ["Cognee MCP"]="8000"
    ["Langfuse"]="3000"
    ["Uptime Kuma"]="3002"
    ["OpenWork MCP"]="8765"
    ["SEPCC proxy"]="8082"
)

degraded=0

for service in "${!services[@]}"; do
    port="${services[$service]}"
    (echo >/dev/tcp/localhost/"$port") &>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "\e[32m[ONLINE] $service is running on port $port\e[0m"
    else
        echo -e "\e[31m[OFFLINE] $service is down on port $port\e[0m"
        degraded=1
    fi
done

echo "-------------------------------------"

if [ $degraded -eq 1 ]; then
    echo -e "\e[33mStatus: DEGRADED. Check offline services.\e[0m"
else
    echo -e "\e[32mStatus: ALL SERVICES HEALTHY.\e[0m"
fi
