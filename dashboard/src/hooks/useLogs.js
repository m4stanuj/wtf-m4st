import { useState, useCallback, useEffect } from 'react';
import { API_BASE, authHeaders } from '../config';

export function useLogs(token) {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const refresh = useCallback(async () => {
    if (!token) {
      setLogs([]);
      setError('Enter a monitoring token to read logs.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${API_BASE}/api/logs?limit=25`, {
        headers: authHeaders(token),
        signal: AbortSignal.timeout(3000),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setLogs(Array.isArray(data) ? data : []);
    } catch (err) {
      setLogs([]);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    const initial = setTimeout(refresh, 0);
    const timer = token ? setInterval(refresh, 5000) : null;
    return () => {
      clearTimeout(initial);
      clearInterval(timer);
    };
  }, [refresh, token]);

  const totalRuns = logs.length;

  return { logs, loading, error, refresh, totalRuns };
}
