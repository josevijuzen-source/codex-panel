import {
  Play,
  RotateCw,
  Square,
  Folder,
  Terminal,
  Database,
  Shield,
  Globe,
  Archive,
  FileText,
  Settings,
  BarChart3,
  Trash2,
} from "lucide-react";

interface Props {
  onStart?: () => void;
  onRestart?: () => void;
  onStop?: () => void;
  onFiles?: () => void;
  onTerminal?: () => void;
  onDatabase?: () => void;
  onSSL?: () => void;
  onDomains?: () => void;
  onBackups?: () => void;
  onLogs?: () => void;
  onSettings?: () => void;
  onStats?: () => void;
  onDelete?: () => void;
}

export default function WebsiteActions(props: Props) {
  const actions = [
    {
      icon: Play,
      label: "Start",
      color: "bg-green-600 hover:bg-green-700",
      fn: props.onStart,
    },
    {
      icon: RotateCw,
      label: "Restart",
      color: "bg-yellow-600 hover:bg-yellow-700",
      fn: props.onRestart,
    },
    {
      icon: Square,
      label: "Stop",
      color: "bg-red-600 hover:bg-red-700",
      fn: props.onStop,
    },
    {
      icon: Folder,
      label: "Files",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onFiles,
    },
    {
      icon: Terminal,
      label: "Terminal",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onTerminal,
    },
    {
      icon: Database,
      label: "Database",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onDatabase,
    },
    {
      icon: Shield,
      label: "SSL",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onSSL,
    },
    {
      icon: Globe,
      label: "Domains",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onDomains,
    },
    {
      icon: Archive,
      label: "Backups",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onBackups,
    },
    {
      icon: FileText,
      label: "Logs",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onLogs,
    },
    {
      icon: Settings,
      label: "Settings",
      color: "bg-slate-700 hover:bg-slate-600",
      fn: props.onSettings,
    },
    {
      icon: BarChart3,
      label: "Statistics",
      color: "bg-indigo-600 hover:bg-indigo-700",
      fn: props.onStats,
    },
    {
      icon: Trash2,
      label: "Delete",
      color: "bg-red-700 hover:bg-red-800",
      fn: props.onDelete,
    },
  ];

  return (
    <div className="grid grid-cols-2 gap-3 md:grid-cols-4 xl:grid-cols-5">
      {actions.map((action) => {
        const Icon = action.icon;

        return (
          <button
            key={action.label}
            onClick={action.fn}
            disabled={!action.fn}
            className={`${action.color} flex items-center justify-center gap-2 rounded-xl px-4 py-3 font-medium text-white transition ${
              !action.fn ? "cursor-not-allowed opacity-50" : ""
            }`}
          >
            <Icon size={18} />
            {action.label}
          </button>
        );
      })}
    </div>
  );
}