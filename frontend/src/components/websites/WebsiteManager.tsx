import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import toast from "react-hot-toast";

import WebsiteActions from "./WebsiteActions";
import Overview from "../website-manager/Overview";

import {
  startWebsite,
  stopWebsite,
  restartWebsite,
} from "../../api/websites";

const tabs = [
  "Overview",
  "Files",
  "Terminal",
  "Databases",
  "SSL",
  "Domains",
  "Backups",
  "Logs",
  "Settings",
];

export default function WebsiteManager() {
  const [tab, setTab] = useState("Overview");

  const navigate = useNavigate();
  const { id } = useParams();

  const websiteId = Number(id);

  const handleStart = async () => {
    try {
      const data = await startWebsite(websiteId);
      toast.success(data.message);
    } catch (err) {
      console.error(err);
      toast.error("Failed to start website");
    }
  };

  const handleStop = async () => {
    try {
      const data = await stopWebsite(websiteId);
      toast.success(data.message);
    } catch (err) {
      console.error(err);
      toast.error("Failed to stop website");
    }
  };

  const handleRestart = async () => {
    try {
      const data = await restartWebsite(websiteId);
      toast.success(data.message);
    } catch (err) {
      console.error(err);
      toast.error("Failed to restart website");
    }
  };

  const handleDelete = () => {
    toast.success("Delete feature");
  };

  return (
    <div className="space-y-6">

      <div className="rounded-2xl border border-slate-700 bg-slate-900 p-6">

        <div className="flex items-center justify-between">

          <div>

            <h1 className="text-3xl font-bold text-white">
              Website #{websiteId}
            </h1>

            <p className="text-slate-400">
              Website Management
            </p>

          </div>

        </div>

      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">

        {[
          ["CPU Usage", "18%"],
          ["RAM Usage", "1.2 / 4 GB"],
          ["Disk Usage", "6.5 / 20 GB"],
        ].map(([title, value]) => (

          <div
            key={title}
            className="rounded-xl border border-slate-700 bg-slate-900 p-5"
          >

            <p className="text-slate-400">
              {title}
            </p>

            <h2 className="mt-2 text-3xl font-bold text-white">
              {value}
            </h2>

          </div>

        ))}

      </div>

      <WebsiteActions
        onStart={handleStart}
        onRestart={handleRestart}
        onStop={handleStop}

        onFiles={() =>
          navigate(`/file-manager?website=${websiteId}`)
        }

        onTerminal={() =>
          navigate(`/terminal?website=${websiteId}`)
        }

        onDatabase={() =>
          navigate(`/databases?website=${websiteId}`)
        }

        onSSL={() =>
          navigate(`/ssl?website=${websiteId}`)
        }

        onDomains={() =>
          navigate(`/domains?website=${websiteId}`)
        }

        onBackups={() =>
          navigate(`/backups?website=${websiteId}`)
        }

        onLogs={() =>
          navigate(`/logs?website=${websiteId}`)
        }

        onSettings={() =>
          navigate(`/settings?website=${websiteId}`)
        }

        onDelete={handleDelete}
      />

      <div className="flex flex-wrap gap-2">

        {tabs.map((t) => (

          <button
            key={t}
            onClick={() => setTab(t)}
            className={`rounded-lg px-4 py-2 ${
              tab === t
                ? "bg-blue-600 text-white"
                : "bg-slate-800 text-slate-300 hover:bg-slate-700"
            }`}
          >
            {t}
          </button>

        ))}

      </div>

      <div className="rounded-2xl border border-slate-700 bg-slate-900 p-8">

        {tab === "Overview" && (
  <Overview websiteId={websiteId} />
)}

      </div>

    </div>
  );
}