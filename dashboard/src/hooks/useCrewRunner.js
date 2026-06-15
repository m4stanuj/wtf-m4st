import { useState, useCallback } from 'react';
import { API_BASE, authHeaders } from '../config';

export function useCrewRunner(showToast) {
  const [runningCrews, setRunningCrews] = useState({});

  const runCrew = useCallback(async (crewFile, isDryRun = false) => {
    const mode = isDryRun ? 'DRY RUN' : 'LIVE';
    const crewName = crewFile.replace('_crew', '').replace('_', ' ');
    setRunningCrews((prev) => ({ ...prev, [crewFile]: true }));
    showToast?.(`Starting ${crewName} crew [${mode}]...`, 'info');

    try {
      const res = await fetch(`${API_BASE}/agent/run`, {
        method: 'POST',
        headers: authHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({
          crew: crewFile,
          params: { dry_run: isDryRun },
        }),
        signal: AbortSignal.timeout(10000),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.detail || `HTTP ${res.status}`);
      }

      showToast?.(`${crewName} crew started [${mode}]`, 'success');
      return true;
    } catch (err) {
      showToast?.(`Failed to start ${crewName} crew [${mode}]: ${err.message}`, 'error');
      return false;
    } finally {
      setRunningCrews((prev) => ({ ...prev, [crewFile]: false }));
    }
  }, [showToast]);

  const runAll = useCallback(async (isDryRun = true) => {
    showToast?.('Starting all crews...', 'info');
    for (const crew of ['nightly_crew', 'content_crew', 'bugfix_crew']) {
      await runCrew(crew, isDryRun);
    }
    showToast?.('All crew start requests completed', 'info');
  }, [runCrew, showToast]);

  return { runCrew, runAll, runningCrews };
}
