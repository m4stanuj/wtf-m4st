import { useState, useEffect, useRef, useCallback } from 'react';
import { API_BASE, HEALTH_INTERVAL } from '../config';

const OFFLINE_HEALTH = {
  status: 'offline',
  services: {
    openclaw: 'unknown',
    ninerouter: 'unknown',
    falkordb: 'unknown',
    'graphiti-mcp': 'unknown',
    'cognee-mcp': 'unknown',
    langfuse: 'unknown',
    'uptime-kuma': 'unknown',
    'openwork-mcp': 'down',
    sepcc: 'unknown',
  },
};

export function useHealth() {
  const [data, setData] = useState(OFFLINE_HEALTH);
  const [isConnected, setIsConnected] = useState(false);
  const [isLive, setIsLive] = useState(false);
  const intervalRef = useRef(null);

  const refresh = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/health`, {
        signal: AbortSignal.timeout(3000),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();

      if (json.services) {
        json.services['openwork-mcp'] = json.services['openwork-mcp'] || 'healthy';
        json.services.sepcc = json.services.sepcc || 'unknown';
      }

      setData(json);
      setIsConnected(true);
      setIsLive(true);
    } catch {
      setData(OFFLINE_HEALTH);
      setIsConnected(false);
      setIsLive(false);
    }
  }, []);

  useEffect(() => {
    const initial = setTimeout(refresh, 0);
    intervalRef.current = setInterval(refresh, HEALTH_INTERVAL);
    return () => {
      clearTimeout(initial);
      clearInterval(intervalRef.current);
    };
  }, [refresh]);

  const healthyCount = data?.services
    ? Object.values(data.services).filter((status) => status === 'healthy').length
    : 0;

  return { data, isConnected, isLive, refresh, healthyCount };
}
