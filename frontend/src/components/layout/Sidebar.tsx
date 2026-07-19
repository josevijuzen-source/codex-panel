import {
  LayoutDashboard,
  Globe,
  Folder,
  Terminal,
  Database,
  Shield,
  HardDrive,
  FileText,
  Mail,
  Users,
  Server,
  Settings,
  Blocks,
  Network,
  Globe2,
  FolderOpen,
} from "lucide-react";

import { NavLink } from "react-router-dom";

const menu = [
  {
    icon: LayoutDashboard,
    label: "Dashboard",
    path: "/dashboard",
  },
  {
    icon: Globe,
    label: "Websites",
    path: "/websites",
  },
  {
    icon: Globe2,
    label: "Domains",
    path: "/domains",
  },
  {
    icon: Network,
    label: "DNS Manager",
    path: "/dns",
  },
  {
    icon: FolderOpen,
    label: "FTP Manager",
    path: "/ftp",
  },
  {
    icon: Blocks,
    label: "WordPress",
    path: "/wordpress",
  },
  {
    icon: Folder,
    label: "File Manager",
    path: "/file-manager",
  },
  {
    icon: Terminal,
    label: "Terminal",
    path: "/terminal",
  },
  {
    icon: Database,
    label: "Databases",
    path: "/databases",
  },
  {
    icon: Shield,
    label: "SSL",
    path: "/ssl",
  },
  {
    icon: HardDrive,
    label: "Backups",
    path: "/backups",
  },
  {
    icon: FileText,
    label: "Logs",
    path: "/logs",
  },
  {
    icon: Mail,
    label: "Email",
    path: "/email",
  },
  {
    icon: Server,
    label: "Server",
    path: "/server",
  },
  {
    icon: Users,
    label: "Users",
    path: "/users",
  },
  {
    icon: Settings,
    label: "Settings",
    path: "/settings",
  },
];

export default function Sidebar() {
  return (
    <aside className="flex h-screen w-72 flex-col border-r border-slate-800 bg-slate-950">
      {/* Logo */}
      <div className="border-b border-slate-800 p-6">
        <h1 className="text-3xl font-bold text-blue-500">
          Codex Panel
        </h1>

        <p className="mt-1 text-sm text-slate-400">
          Modern Web Hosting Panel
        </p>
      </div>

      {/* Menu */}
      <nav className="flex-1 space-y-2 overflow-y-auto p-4">
        {menu.map((item) => (
          <NavLink
            key={item.label}
            to={item.path}
            className={({ isActive }) =>
              `flex items-center gap-4 rounded-xl px-4 py-3 transition-all ${
                isActive
                  ? "bg-blue-600 text-white shadow-lg"
                  : "text-slate-300 hover:bg-slate-800 hover:text-white"
              }`
            }
          >
            <item.icon size={20} />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="border-t border-slate-800 p-5">
        <div className="rounded-xl bg-slate-900 p-4">
          <p className="text-xs text-slate-400">
            Version
          </p>

          <h3 className="mt-1 font-bold text-white">
            Codex Panel v1.0.0
          </h3>

          <p className="mt-2 text-xs text-green-400">
            ● Server Online
          </p>
        </div>
      </div>
    </aside>
  );
}