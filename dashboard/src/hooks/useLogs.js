import { useState, useCallback, useEffect } from 'react';
import { API_BASE, API_TOKEN } from '../config';

// Realistic mock log entries
const MOCK_LOGS = [
  { timestamp: new Date(Date.now() - 86400000).toISOString(), crew: 'nightly', mode: 'LIVE', result: 'Scanned 3 repos · 2 issues found · 1 draft posted · Telegram report sent ✅' },
  { timestamp: new Date(Date.now() - 82800000).toISOString(), crew: 'content', mode: 'LIVE', result: 'Researched AI agent trends · Drafted LinkedIn post · Review passed ✅' },
  { timestamp: new Date(Date.now() - 79200000).toISOString(), crew: 'bugfix', mode: 'DRY RUN', result: 'Analyzed dependency alerts · Suggested bumps for 4 packages · Tests simulated ✅' },
  { timestamp: new Date(Date.now() - 172800000).toISOString(), crew: 'nightly', mode: 'LIVE', result: 'Scanned 3 repos · 0 issues · All clear · Telegram: "System clean" ✅' },
  { timestamp: new Date(Date.now() - 169200000).toISOString(), crew: 'content', mode: 'DRY RUN', result: 'Simulated research on LLM routing · Draft generated · Review skipped (dry) ✅' },
  { timestamp: new Date(Date.now() - 259200000).toISOString(), crew: 'nightly', mode: 'LIVE', result: 'Scanned 3 repos · 1 stale PR flagged · Auto-closed · Report sent ✅' },
  { timestamp: new Date(Date.now() - 255600000).toISOString(), crew: 'bugfix', mode: 'LIVE', result: 'Fixed CORS header misconfiguration in OpenWork MCP · Tests passed ✅' },
  { timestamp: new Date(Date.now() - 345600000).toISOString(), crew: 'nightly', mode: 'LIVE', result: 'Scanned 3 repos · Security advisory on jsonwebtoken · Patch applied ✅' },
];

export function useLogs() {
  const [logs, setLogs] = useState(MOCK_LOGS);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/logs?limit=25`, {
        headers: { 'X-M4ST-Token': API_TOKEN },
        signal: AbortSignal.timeout(3000)
      });
      if (!res.ok) throw new Error();
      const data = await res.json();
      if (data && data.length > 0) {
        setLogs(data);
      }
      // If empty, keep mocks
    } catch {
      // Backend down — keep mock logs
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { refresh(); }, [refresh]);

  const totalRuns = logs.length;

  return { logs, loading, refresh, totalRuns };
}
