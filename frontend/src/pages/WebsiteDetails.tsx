import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import toast from "react-hot-toast";

import {
  getWebsites,
  startWebsite,
  stopWebsite,
  restartWebsite,
  deleteWebsite,
} from "../api/websites";

import {
  Folder,
  Terminal,
  Database,
  Shield,
  FileText,
  Play,
  Square,
  RotateCw,
  Trash2,
} from "lucide-react";

export default function WebsiteDetails() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [website, setWebsite] = useState<any>(null);

  useEffect(() => {
    loadWebsite();
  }, []);

  const loadWebsite = async () => {
    try {
      const data = await getWebsites();

      const site = data.websites.find(
        (w: any) => w.id === Number(id)
      );

      setWebsite(site);
    } catch (error) {
      console.error(error);
    }
  };

  const handleStart = async () => {
    try {
      await startWebsite(website.id);
      toast.success("Website started");
      await loadWebsite();
    } catch (error) {
      console.error(error);
      toast.error("Failed to start website");
    }
  };

  const handleStop = async () => {
    try {
      await stopWebsite(website.id);
      toast.success("Website stopped");
      await loadWebsite();
    } catch (error) {
      console.error(error);
      toast.error("Failed to stop website");
    }
  };

  const handleRestart = async () => {
    try {
      await restartWebsite(website.id);
      toast.success("Website restarted");
      await loadWebsite();
    } catch (error) {
      console.error(error);
      toast.error("Failed to restart website");
    }
  };

  const handleDelete = async () => {
    if (!confirm("Delete this website?")) return;

    try {
      await deleteWebsite(website.id);
      toast.success("Website deleted");
      navigate("/websites");
    } catch (error) {
      console.error(error);
      toast.error("Failed to delete website");
    }
  };

  if (!website) {
    return (
      <div className="p-8 text-white">
        Loading...
      </div>
    );
  }

  return (
    <div className="space-y-8">

      <div className="rounded-2xl border border-slate-700 bg-slate-900 p-8">
        <div className="flex items-center justify-between">

          <div>
            <h1 className="text-4xl font-bold text-white">
              {website.domain}
            </h1>

            <p className="text-slate-400">
              {website.runtime}
            </p>
          </div>

          <span
            className={`rounded-full px-4 py-2 text-white ${
              website.status === "Running"
                ? "bg-green-600"
                : "bg-red-600"
            }`}
          >
            {website.status}
          </span>

        </div>
      </div>

      <div className="grid grid-cols-4 gap-5">

        <button
          onClick={() => navigate(`/file-manager?website=${website.id}`)}
          className="rounded-2xl bg-slate-900 p-6 hover:bg-slate-800"
        >
          <Folder className="mb-3 text-yellow-400" size={34} />
          <h3 className="font-semibold text-white">Files</h3>
        </button>

        <button
          onClick={() => navigate(`/terminal?website=${website.id}`)}
          className="rounded-2xl bg-slate-900 p-6 hover:bg-slate-800"
        >
          <Terminal className="mb-3 text-green-400" size={34} />
          <h3 className="font-semibold text-white">Terminal</h3>
        </button>

        <button
          onClick={() => navigate(`/databases?website=${website.id}`)}
          className="rounded-2xl bg-slate-900 p-6 hover:bg-slate-800"
        >
          <Database className="mb-3 text-blue-400" size={34} />
          <h3 className="font-semibold text-white">Database</h3>
        </button>

        <button
          onClick={() => navigate(`/ssl?website=${website.id}`)}
          className="rounded-2xl bg-slate-900 p-6 hover:bg-slate-800"
        >
          <Shield className="mb-3 text-red-400" size={34} />
          <h3 className="font-semibold text-white">SSL</h3>
        </button>

        <button
          onClick={() => navigate(`/logs?website=${website.id}`)}
          className="rounded-2xl bg-slate-900 p-6 hover:bg-slate-800"
        >
          <FileText className="mb-3 text-purple-400" size={34} />
          <h3 className="font-semibold text-white">Logs</h3>
        </button>

        <button
          onClick={handleStart}
          className="rounded-2xl bg-green-600 p-6 hover:bg-green-700"
        >
          <Play className="mb-3 text-white" size={34} />
          <h3 className="font-semibold text-white">Start</h3>
        </button>

        <button
          onClick={handleRestart}
          className="rounded-2xl bg-orange-600 p-6 hover:bg-orange-700"
        >
          <RotateCw className="mb-3 text-white" size={34} />
          <h3 className="font-semibold text-white">Restart</h3>
        </button>

        <button
          onClick={handleStop}
          className="rounded-2xl bg-red-600 p-6 hover:bg-red-700"
        >
          <Square className="mb-3 text-white" size={34} />
          <h3 className="font-semibold text-white">Stop</h3>
        </button>

      </div>

      <div className="rounded-2xl border border-red-700 bg-red-950 p-6">

        <h2 className="mb-4 text-2xl font-bold text-red-400">
          Danger Zone
        </h2>

        <button
          onClick={handleDelete}
          className="flex items-center gap-2 rounded-lg bg-red-600 px-6 py-3 text-white hover:bg-red-700"
        >
          <Trash2 size={18} />
          Delete Website
        </button>

      </div>

    </div>
  );
}