import { useEffect, useState } from "react";
import {
  Cpu,
  MemoryStick,
  HardDrive,
  Activity,
  Server as ServerIcon,
  Wifi,
} from "lucide-react";
import { getServerStats } from "../api/server";

export default function Server() {
  const [server, setServer] = useState<any>(null);

  useEffect(() => {
    loadStats();

    const interval = setInterval(loadStats, 1000);

    return () => clearInterval(interval);
  }, []);

  async function loadStats() {
    try {
      const data = await getServerStats();
      setServer(data);
    } catch (err) {
      console.error(err);
    }
  }

  const stats = [
    {
      title: "CPU Usage",
      value: server ? `${server.cpu.toFixed(1)}%` : "--",
      percent: server ? server.cpu : 0,
      color: "bg-red-500",
      icon: Cpu,
    },
    {
      title: "RAM Usage",
      value: server
        ? `${(server.ramUsed / 1024 / 1024 / 1024).toFixed(1)} GB / ${(server.ramTotal / 1024 / 1024 / 1024).toFixed(1)} GB`
        : "--",
      percent: server
        ? (server.ramUsed / server.ramTotal) * 100
        : 0,
      color: "bg-blue-500",
      icon: MemoryStick,
    },
    {
      title: "Disk Usage",
      value: server
        ? `${(server.diskUsed / 1024 / 1024 / 1024).toFixed(1)} GB / ${(server.diskTotal / 1024 / 1024 / 1024).toFixed(1)} GB`
        : "--",
      percent: server
        ? (server.diskUsed / server.diskTotal) * 100
        : 0,
      color: "bg-yellow-500",
      icon: HardDrive,
    },
    {
      title: "Network",
      value: "Live",
      percent: 50,
      color: "bg-green-500",
      icon: Wifi,
    },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-4xl font-bold text-white">
          Server Monitor
        </h1>

        <p className="text-slate-400">
          Real-time VPS statistics
        </p>
      </div>

      <div className="grid grid-cols-2 gap-6">
        {stats.map((item) => (
          <div
            key={item.title}
            className="rounded-2xl border border-slate-800 bg-slate-900 p-6"
          >
            <div className="mb-5 flex items-center justify-between">
              <div>
                <p className="text-slate-400">
                  {item.title}
                </p>

                <h2 className="mt-2 text-3xl font-bold text-white">
                  {item.value}
                </h2>
              </div>

              <item.icon
                size={36}
                className="text-blue-400"
              />
            </div>

            <div className="h-3 rounded-full bg-slate-800">
              <div
                className={`${item.color} h-3 rounded-full transition-all duration-700`}
                style={{
                  width: `${Math.min(item.percent, 100)}%`,
                }}
              />
            </div>
          </div>
        ))}
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-8">
        <div className="mb-6 flex items-center gap-3">
          <Activity
            className="text-green-400"
            size={28}
          />

          <h2 className="text-2xl font-bold text-white">
            Server Activity
          </h2>
        </div>

        <div className="flex h-80 items-center justify-center rounded-xl border border-dashed border-slate-700 text-slate-500">
          Live Graphs Coming Soon
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6">
          <ServerIcon
            className="mb-4 text-green-400"
            size={30}
          />

          <h3 className="text-xl font-bold text-white">
            Server Status
          </h3>

          <p className="mt-2 text-green-400 font-semibold">
            ● Online
          </p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6">
          <h3 className="text-xl font-bold text-white">
            Uptime
          </h3>

          <p className="mt-4 text-3xl font-bold text-blue-400">
            {server
              ? `${Math.floor(server.uptime.uptime / 86400)} Days`
              : "--"}
          </p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6">
          <h3 className="text-xl font-bold text-white">
            Operating System
          </h3>

          <p className="mt-4 text-lg text-slate-300 break-words">
            {server ? server.os.distro : "--"}
          </p>
        </div>
      </div>
    </div>
  );
}