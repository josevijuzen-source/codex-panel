import { useEffect, useState } from "react";
import { getMonitor } from "../../api/monitor";

interface MonitorData {
  os: {
    platform: string;
    release: string;
    hostname: string;
    uptime: number;
    architecture: string;
  };

  cpu: {
    model: string;
    cores: number;
    usage: number;
  };

  ram: {
    total: number;
    used: number;
    free: number;
    usage: number;
  };

  disk: {
    total: number;
    used: number;
    free: number;
    usage: number;
  };

  services: {
    nginx: boolean;
    mysql: boolean;
  };

  node: string;
}

export default function ServerMonitor() {
  const [stats, setStats] = useState<MonitorData | null>(null);
  const [loading, setLoading] = useState(true);

  const loadStats = async () => {
    try {
      const res = await getMonitor();
      setStats(res.stats);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadStats();

    const interval = setInterval(loadStats, 5000);

    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return <div className="text-center p-6">Loading server statistics...</div>;
  }

  if (!stats) {
    return <div className="text-center p-6">Unable to load server statistics.</div>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6 text-white">
        <h2 className="mb-3 text-xl font-bold text-white">CPU</h2>
        <p><strong>Model:</strong> {stats.cpu.model}</p>
        <p><strong>Cores:</strong> {stats.cpu.cores}</p>
        <p><strong>Load:</strong> {stats.cpu.usage.toFixed(2)}</p>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6 text-white">
        <h2 className="mb-3 text-xl font-bold text-white">RAM</h2>
        <p>{stats.ram.used} MB / {stats.ram.total} MB</p>
        <p>Usage: {stats.ram.usage}%</p>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6 text-white">
        <h2 className="mb-3 text-xl font-bold text-white">Disk</h2>
        <p>{stats.disk.used} MB / {stats.disk.total} MB</p>
        <p>Usage: {stats.disk.usage}%</p>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6 text-white">
        <h2 className="mb-3 text-xl font-bold text-white">Operating System</h2>
        <p>{stats.os.platform}</p>
        <p>{stats.os.release}</p>
        <p>{stats.os.architecture}</p>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6 text-white">
        <h2 className="mb-3 text-xl font-bold text-white">Services</h2>
        <p>Nginx: {stats.services.nginx ? "🟢 Running" : "🔴 Stopped"}</p>
        <p>MySQL: {stats.services.mysql ? "🟢 Running" : "🔴 Stopped"}</p>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6 text-white">
        <h2 className="mb-3 text-xl font-bold text-white">System</h2>
        <p><strong>Hostname:</strong> {stats.os.hostname}</p>
        <p><strong>Node.js:</strong> {stats.node}</p>
        <p><strong>Uptime:</strong> {Math.floor(stats.os.uptime / 3600)} hours</p>
      </div>

    </div>
  );
}