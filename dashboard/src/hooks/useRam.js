import { useState, useEffect, useCallback } from 'react';
import { API_BASE, API_TOKEN, RAM_INTERVAL } from '../config';

// Realistic mock — based on actual M4ST RAM budget
const MOCK_RAM = {
  usedGb: 7.15,
  totalGb: 16,
  containers: {
    'falkordb': 1024,
    'langfuse': 600,
    'openclaw': 500,
    'cognee-mcp': 500,
    'graphiti-mcp': 400,
    'ninerouter': 200,
    'openwork-mcp': 200,
    'uptime-kuma': 200,
    'sepcc': 50
  },
  pct: 45,
  estimated: false
};

export function useRam() {
  const [ram, setRam] = useState(MOCK_RAM);

  const refresh = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/api/ram`, {
        headers: { 'X-M4ST-Token': API_TOKEN },
        signal: AbortSignal.timeout(3000)
      });
      if (!res.ok) throw new Error();
      const data = await res.json();
      const pct = Math.round((data.used_gb / data.total_gb) * 100);
      setRam({
        usedGb: data.used_gb,
        totalGb: data.total_gb,
        containers: data.containers || {},
        pct,
        estimated: !!data.estimated
      });
    } catch {
      // Keep mock data — dashboard stays alive
    }
  }, []);

  useEffect(() => {
    refresh();
    const id = setInterval(refresh, RAM_INTERVAL);
    return () => clearInterval(id);
  }, [refresh]);

  return ram;
}
