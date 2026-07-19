import { Plus, Search } from "lucide-react";
import { useEffect, useState } from "react";

import { getWebsites } from "../api/websites";
import WebsiteTable from "../components/websites/WebsiteTable";
import CreateWebsiteModal from "../components/websites/CreateWebsiteModal";

export default function Websites() {
  const [open, setOpen] = useState(false);

  const [websites, setWebsites] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const loadWebsites = async () => {
    try {
      const data = await getWebsites();

      setWebsites(data.websites ?? []);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadWebsites();
  }, []);

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-4xl font-bold text-white">
            Websites
          </h1>

          <p className="text-slate-400">
            Manage all hosted websites
          </p>
        </div>

        <button
          onClick={() => setOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-blue-600 px-5 py-3 text-white hover:bg-blue-700"
        >
          <Plus size={20} />
          Create Website
        </button>
      </div>

      <div className="relative">
        <Search
          className="absolute left-4 top-4 text-slate-400"
          size={18}
        />

        <input
          placeholder="Search websites..."
          className="w-full rounded-xl border border-slate-700 bg-slate-800 py-3 pl-12 pr-4 text-white"
        />
      </div>

      {loading ? (
        <div className="rounded-2xl border border-slate-700 bg-slate-900 p-10 text-center text-slate-400">
          Loading websites...
        </div>
      ) : (
        <WebsiteTable websites={websites} />
      )}

      <CreateWebsiteModal
        open={open}
        onClose={() => {
          setOpen(false);
          loadWebsites();
        }}
      />
    </div>
  );
}