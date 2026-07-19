import { useEffect, useState } from "react";
import {
  Globe,
  Database,
  Users,
  Activity,
  Play,
} from "lucide-react";

import { getDashboard } from "../api/dashboard";
import ServerMonitor from "../components/dashboard/ServerMonitor";

interface DashboardStats {
  websites: number;
  databases: number;
  users: number;
  running: number;
}

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    websites: 0,
    databases: 0,
    users: 0,
    running: 0,
  });

  const loadDashboard = async () => {
    try {
      const res = await getDashboard();
      setStats(res.stats);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    loadDashboard();

    const interval = setInterval(loadDashboard, 5000);

    return () => clearInterval(interval);
  }, []);

  const cards = [
    {
      title: "Websites",
      value: stats.websites,
      icon: Globe,
      color: "text-blue-400",
    },
    {
      title: "Databases",
      value: stats.databases,
      icon: Database,
      color: "text-green-400",
    },
    {
      title: "Users",
      value: stats.users,
      icon: Users,
      color: "text-purple-400",
    },
    {
      title: "Running",
      value: stats.running,
      icon: Play,
      color: "text-emerald-400",
    },
  ];

  return (
    <div className="space-y-8">

      <div>
        <h1 className="text-4xl font-bold text-white">
          Dashboard
        </h1>

        <p className="text-slate-400">
          Welcome to Codex Panel
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        {cards.map((card) => (
          <div
            key={card.title}
            className="rounded-2xl border border-slate-800 bg-slate-900 p-6"
          >
            <div className="flex items-center justify-between">

              <div>
                <p className="text-slate-400">
                  {card.title}
                </p>

                <h2 className="mt-2 text-3xl font-bold text-white">
                  {card.value}
                </h2>
              </div>

              <card.icon
                size={38}
                className={card.color}
              />

            </div>
          </div>
        ))}
      </div>

      <ServerMonitor />

      <div className="rounded-2xl border border-slate-800 bg-slate-900 p-8">

        <div className="mb-5 flex items-center gap-3">

          <Activity
            className="text-green-400"
            size={28}
          />

          <h2 className="text-2xl font-bold text-white">
            Live Server Activity
          </h2>

        </div>

        <div className="h-72 rounded-xl border border-dashed border-slate-700 flex items-center justify-center text-slate-500">
          Live Charts Coming Soon...
        </div>

      </div>

    </div>
  );
}