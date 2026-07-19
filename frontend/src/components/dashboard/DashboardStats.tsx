import {
  Cpu,
  HardDrive,
  MemoryStick,
  Globe,
  Users,
  Database,
} from "lucide-react";

const stats = [
  {
    title: "CPU Usage",
    value: "24%",
    icon: Cpu,
    color: "bg-blue-600",
  },
  {
    title: "RAM Usage",
    value: "5.8 GB",
    icon: MemoryStick,
    color: "bg-green-600",
  },
  {
    title: "Disk Usage",
    value: "120 GB",
    icon: HardDrive,
    color: "bg-orange-600",
  },
  {
    title: "Websites",
    value: "18",
    icon: Globe,
    color: "bg-purple-600",
  },
  {
    title: "Users",
    value: "5",
    icon: Users,
    color: "bg-pink-600",
  },
  {
    title: "Databases",
    value: "21",
    icon: Database,
    color: "bg-cyan-600",
  },
];

export default function DashboardStats() {
  return (
    <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
      {stats.map((stat) => (
        <div
          key={stat.title}
          className="rounded-2xl border border-slate-700 bg-slate-800 p-6 shadow-lg hover:border-blue-500 transition"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-slate-400">{stat.title}</p>

              <h2 className="mt-2 text-3xl font-bold text-white">
                {stat.value}
              </h2>
            </div>

            <div className={`${stat.color} rounded-xl p-4`}>
              <stat.icon size={28} className="text-white" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}