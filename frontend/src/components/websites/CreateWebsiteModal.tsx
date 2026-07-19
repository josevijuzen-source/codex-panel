import { useState } from "react";
import { X } from "lucide-react";
import toast from "react-hot-toast";
import { createWebsite } from "../../api/websites";

interface Props {
  open: boolean;
  onClose: () => void;
}

export default function CreateWebsiteModal({
  open,
  onClose,
}: Props) {
  const [loading, setLoading] = useState(false);

  const [form, setForm] = useState({
    name: "",
    domain: "",
    runtime: "🌐 Static Website (HTML/CSS/JS)",
    cpu: 1,
    ram: 1024,
    disk: 10240,
    ssl: false,
    ownerId: 1,
  });

  if (!open) return null;

  const handleCreate = async () => {
  if (!form.name.trim()) {
    toast.error("Website name is required");
    return;
  }

  if (!form.domain.trim()) {
    toast.error("Domain is required");
    return;
  }

  try {
    setLoading(true);

    const response = await createWebsite(form);

    if (response.success) {
      toast.success(response.message || "Website created successfully");
      onClose();

      setForm({
        name: "",
        domain: "",
        runtime: "🌐 Static Website (HTML/CSS/JS)",
        cpu: 1,
        ram: 1024,
        disk: 10240,
        ssl: false,
        ownerId: 1,
      });
    }
  } catch (err: any) {
    console.error(err);

    toast.error(
      err?.response?.data?.message || "Failed to create website"
    );
  } finally {
    setLoading(false);
  }
};

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">

      <div className="w-full max-w-5xl rounded-2xl border border-slate-700 bg-slate-900 p-8">

        <div className="mb-8 flex items-center justify-between">
          <div>
            <h2 className="text-3xl font-bold text-white">
              Create Website
            </h2>

            <p className="text-slate-400">
              Deploy a new website
            </p>
          </div>

          <button onClick={onClose}>
            <X className="text-slate-400 hover:text-white" />
          </button>
        </div>

        <div className="grid grid-cols-2 gap-5">

          <input
            placeholder="Website Name"
            value={form.name}
            onChange={(e) =>
              setForm({ ...form, name: e.target.value })
            }
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
          />

          <input
            placeholder="Domain"
            value={form.domain}
            onChange={(e) =>
              setForm({ ...form, domain: e.target.value })
            }
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
          />

          <select
            value={form.runtime}
            onChange={(e) =>
              setForm({ ...form, runtime: e.target.value })
            }
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
          >
            <option>🌐 Static Website (HTML/CSS/JS)</option>
            <option>⚛ React (Vite)</option>
            <option>▲ Next.js</option>
            <option>🟢 Node.js (Express)</option>
            <option>🐍 Python (Flask)</option>
            <option>🐍 Python (Django)</option>
            <option>🐘 PHP 8.4</option>
            <option>📝 Laravel</option>
            <option>🧩 WordPress</option>
          </select>

          <input
            type="number"
            placeholder="CPU"
            value={form.cpu}
            onChange={(e) =>
              setForm({
                ...form,
                cpu: Number(e.target.value),
              })
            }
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
          />

          <input
            type="number"
            placeholder="RAM (MB)"
            value={form.ram}
            onChange={(e) =>
              setForm({
                ...form,
                ram: Number(e.target.value),
              })
            }
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
          />

          <input
            type="number"
            placeholder="Disk (MB)"
            value={form.disk}
            onChange={(e) =>
              setForm({
                ...form,
                disk: Number(e.target.value),
              })
            }
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
          />

          <label className="flex items-center gap-3 text-white">

            <input
              type="checkbox"
              checked={form.ssl}
              onChange={(e) =>
                setForm({
                  ...form,
                  ssl: e.target.checked,
                })
              }
            />

            Enable SSL

          </label>

        </div>

        <div className="mt-8 flex justify-end gap-4">

          <button
            onClick={onClose}
            className="rounded-xl border border-slate-700 px-6 py-3 text-white"
          >
            Cancel
          </button>

          <button
            disabled={loading}
            onClick={handleCreate}
            className="rounded-xl bg-blue-600 px-8 py-3 font-semibold text-white hover:bg-blue-700"
          >
            {loading ? "Creating..." : "Create Website"}
          </button>

        </div>

      </div>

    </div>
  );
}