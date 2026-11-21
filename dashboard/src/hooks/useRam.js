import { useState, useEffect, useCallback } from 'react';
import { API_BASE, RAM_INTERVAL, authHeaders } from '../config';

const OFFLINE_RAM = {
  usedGb: 0,
  totalGb: 16,
  containers: {},
  pct: 0,
  estimated: true,
  offline: true,
};

export function useRam(token) {
  const [ram, setRam] = useState(OFFLINE_RAM);

  const refresh = useCallback(async () => {
    if (!token) {
      setRam(OFFLINE_RAM);
      return;
    }
    try {
      const res = await fetch(`${API_BASE}/api/ram`, {
        headers: authHeaders(token),
        signal: AbortSignal.timeout(3000),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      if (!data.available) {
        setRam(OFFLINE_RAM);
        return;
      }
      const pct = Math.round((data.used_gb / data.total_gb) * 100);
      setRam({
        usedGb: data.used_gb,
        totalGb: data.total_gb,
        containers: data.containers || {},
        pct,
        estimated: !!data.estimated,
        offline: false,
      });
    } catch {
      setRam(OFFLINE_RAM);
    }
  }, [token]);

  useEffect(() => {
    const initial = setTimeout(refresh, 0);
    const id = setInterval(refresh, RAM_INTERVAL);
    return () => {
      clearTimeout(initial);
      clearInterval(id);
    };
  }, [refresh]);

  return ram;
}
