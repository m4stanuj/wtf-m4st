import { useState, useCallback, useEffect } from 'react';
import { API_BASE, API_TOKEN, authHeaders } from '../config';

export function useLogs() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${API_BASE}/api/logs?limit=25`, {
        headers: authHeaders(),
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
  }, []);

  useEffect(() => {
    const initial = setTimeout(refresh, 0);
    return () => clearTimeout(initial);
  }, [refresh]);

  useEffect(() => {
    if (!API_TOKEN) return undefined;

    const base = API_BASE || window.location.origin;
    const url = new URL('/api/logs/stream', base);
    url.searchParams.set('token', API_TOKEN);
    const source = new EventSource(url.toString());

    source.onmessage = (event) => {
      try {
        const entry = JSON.parse(event.data);
        setLogs((current) => [...current, entry].slice(-25));
        setError(null);
      } catch {
        // Ignore malformed log lines; the polling fallback still handles history.
      }
    };
    source.onerror = () => {
      setError('log stream disconnected');
    };

    return () => source.close();
  }, []);

  const totalRuns = logs.length;

  return { logs, loading, error, refresh, totalRuns };
}
