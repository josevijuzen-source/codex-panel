import { useState } from "react";
import {
  Globe,
  Play,
  Square,
  RotateCw,
  Settings,
  Trash2,
} from "lucide-react";
import toast from "react-hot-toast";
import {
  startWebsite,
  stopWebsite,
  restartWebsite,
  deleteWebsite,
  deployWebsite,
  installWordPress,
} from "../../api/websites";
import { useNavigate } from "react-router-dom";

interface Website {
  id: number;
  domain: string;
  owner?: {
  id: number;
  name: string;
};
  runtime: string;
  ssl: boolean;
  status: string;
}

interface Props {
  websites: Website[];
}

export default function WebsiteTable({ websites }: Props) {
  const navigate = useNavigate();

  const [deleteId, setDeleteId] = useState<number | null>(null);

  const handleStart = async (id: number) => {
    try {
      await startWebsite(id);
      toast.success("Website started");
      window.location.reload();
    } catch (error) {
      console.error(error);
      toast.error("Failed to start website");
    }
  };

  const handleStop = async (id: number) => {
    try {
      await stopWebsite(id);
      toast.success("Website stopped");
      window.location.reload();
    } catch (error) {
      console.error(error);
      toast.error("Failed to stop website");
    }
  };

  const handleRestart = async (id: number) => {
    try {
      await restartWebsite(id);
      toast.success("Website restarted");
      window.location.reload();
    } catch (error) {
      console.error(error);
      toast.error("Failed to restart website");
    }
  };

  const handleDeploy = async (site: Website) => {
  try {
    await deployWebsite(site.domain, site.owner?.id ?? 1);
    toast.success("Website deployed");
    window.location.reload();
  } catch (error) {
    console.error(error);
    toast.error("Failed to deploy website");
  }
};

const handleInstallWordPress = async (id: number) => {
  try {
    await installWordPress(id);
    toast.success("WordPress installed");
  } catch (error) {
    console.error(error);
    toast.error("Failed to install WordPress");
  }
};

  const handleDelete = async () => {
    if (deleteId === null) return;

    try {
      await deleteWebsite(deleteId);
      toast.success("Website deleted");
      setDeleteId(null);
      window.location.reload();
    } catch (error) {
      console.error(error);
      toast.error("Failed to delete website");
    }
  };
    return (
    <>
      <div className="overflow-hidden rounded-2xl border border-slate-700 bg-slate-900">
        <table className="w-full">
          <thead className="bg-slate-800 text-slate-200">
            <tr>
              <th className="p-4 text-left">Domain</th>
              <th className="text-left">Owner</th>
              <th className="text-left">Runtime</th>
              <th className="text-left">SSL</th>
              <th className="text-left">Status</th>
              <th className="text-center">Actions</th>
            </tr>
          </thead>

          <tbody>
            {websites.length === 0 ? (
              <tr>
                <td
                  colSpan={6}
                  className="p-8 text-center text-slate-400"
                >
                  No websites found.
                </td>
              </tr>
            ) : (
              websites.map((site) => (
                <tr
                  key={site.id}
                  className="border-t border-slate-700 hover:bg-slate-800/70"
                >
                  <td className="p-4">
                    <div className="flex items-center gap-3">
                      <Globe
                        size={18}
                        className="text-blue-400"
                      />
                      <span className="text-white">
                        {site.domain}
                      </span>
                    </div>
                  </td>

                  <td className="text-slate-300">
                    {site.owner?.name ?? "-"}
                  </td>

                  <td className="text-slate-300">
                    {site.runtime}
                  </td>

                  <td>
                    <span
                      className={`rounded-full px-3 py-1 text-xs font-semibold text-white ${
                        site.ssl
                          ? "bg-green-600"
                          : "bg-red-600"
                      }`}
                    >
                      {site.ssl ? "Enabled" : "Disabled"}
                    </span>
                  </td>

                  <td>
                    <span
                      className={`rounded-full px-3 py-1 text-xs font-semibold text-white ${
                        site.status === "Running"
                          ? "bg-blue-600"
                          : "bg-red-600"
                      }`}
                    >
                      {site.status}
                    </span>
                  </td>

                  <td>
                    <div className="flex justify-center gap-2">

                      <button
                        onClick={() => handleStart(site.id)}
                        className="rounded bg-green-600 p-2 hover:bg-green-700"
                        title="Start"
                      >
                        <Play size={16} />
                      </button>

                      <button
                        onClick={() => handleStop(site.id)}
                        className="rounded bg-red-600 p-2 hover:bg-red-700"
                        title="Stop"
                      >
                        <Square size={16} />
                      </button>

<button
  onClick={() => handleDeploy(site)}
  className="rounded bg-purple-600 p-2 hover:bg-purple-700"
  title="Deploy"
>
  🚀
</button>

<button
  onClick={() => handleInstallWordPress(site.id)}
  className="rounded bg-indigo-600 p-2 hover:bg-indigo-700"
  title="Install WordPress"
>
  WP
</button>

                      <button
                        onClick={() => handleRestart(site.id)}
                        className="rounded bg-yellow-500 p-2 hover:bg-yellow-600"
                        title="Restart"
                      >
                        <RotateCw size={16} />
                      </button>

                      <button
                        onClick={() =>
                          navigate(`/websites/${site.id}`)
                        }
                        className="rounded bg-blue-600 p-2 hover:bg-blue-700"
                        title="Manage"
                      >
                        <Settings size={16} />
                      </button>

                      <button
                        onClick={() =>
                          setDeleteId(site.id)
                        }
                        className="rounded bg-red-700 p-2 hover:bg-red-800"
                        title="Delete"
                      >
                        <Trash2 size={16} />
                      </button>

                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
            {deleteId !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
            <h2 className="text-2xl font-bold text-white">
              Delete Website
            </h2>

            <p className="mt-3 text-slate-400">
              Are you sure you want to permanently delete this website?
              This action cannot be undone.
            </p>

            <div className="mt-8 flex justify-end gap-3">
              <button
                onClick={() => setDeleteId(null)}
                className="rounded-xl border border-slate-700 px-5 py-2 text-white hover:bg-slate-800"
              >
                Cancel
              </button>

              <button
                onClick={handleDelete}
                className="rounded-xl bg-red-600 px-5 py-2 font-semibold text-white hover:bg-red-700"
              >
                Delete Website
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}