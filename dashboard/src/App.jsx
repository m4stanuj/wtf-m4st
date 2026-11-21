import { useCallback, useState } from 'react';
import { useHealth } from './hooks/useHealth';
import { useRam } from './hooks/useRam';
import { useLogs } from './hooks/useLogs';
import { useToast } from './hooks/useToast';

import ToastContainer from './components/Toast';
import Header from './sections/Header';
import StatsRow from './sections/StatsRow';
import ServicesPanel from './sections/ServicesPanel';
import CrewPanel from './sections/CrewPanel';
import QuickActions from './sections/QuickActions';
import LogsPanel from './sections/LogsPanel';
import ArchitecturePanel from './sections/ArchitecturePanel';
import Footer from './sections/Footer';

import './App.css';

export default function App() {
  const { toasts, showToast, dismissToast } = useToast();
  const { data: health, isConnected, isLive, refresh: refreshHealth, healthyCount } = useHealth();
  const [token, setToken] = useState('');
  const ram = useRam(token);
  const { logs, loading: logsLoading, error: logsError, refresh: refreshLogs, totalRuns } = useLogs(token);

  const handleRefresh = useCallback(() => {
    refreshHealth();
    refreshLogs();
    showToast('Status refreshed', 'info');
  }, [refreshHealth, refreshLogs, showToast]);

  return (
    <div className="app">
      <Header status={health?.status} isConnected={isConnected} isLive={isLive} />

      <form className="section-gap" onSubmit={(event) => {
        event.preventDefault();
        const form = event.currentTarget;
        setToken(String(new FormData(form).get('token') || '').trim());
        form.reset();
      }}>
        <label htmlFor="monitoring-token">Monitoring token</label>{' '}
        <input id="monitoring-token" name="token" type="password" autoComplete="off" required />{' '}
        <button type="submit">Apply</button>{' '}
        {token && <button type="button" onClick={() => setToken('')}>Clear token</button>}
      </form>

      <StatsRow healthyCount={healthyCount} ram={ram} totalRuns={totalRuns} />

      <div className="main-grid">
        <ServicesPanel services={health?.services} />
        <CrewPanel />
      </div>

      <div className="section-gap">
        <QuickActions onRefresh={handleRefresh} />
      </div>

      <div className="section-gap">
        <LogsPanel logs={token ? logs : []} loading={logsLoading} error={logsError} onRefresh={refreshLogs} />
      </div>

      <div className="section-gap">
        <ArchitecturePanel />
      </div>

      <Footer />

      <ToastContainer toasts={toasts} onDismiss={dismissToast} />
    </div>
  );
}
