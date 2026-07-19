import { X } from "lucide-react";

interface Props {
  open: boolean;
  onClose: () => void;
}

export default function CreateUserModal({ open, onClose }: Props) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">

      <div className="w-full max-w-3xl rounded-2xl border border-slate-700 bg-slate-900 p-8 shadow-2xl">

        <div className="mb-8 flex items-center justify-between">

          <div>
            <h2 className="text-3xl font-bold text-white">
              Create User
            </h2>

            <p className="text-slate-400">
              Create a new hosting account
            </p>
          </div>

          <button onClick={onClose}>
            <X className="text-slate-400 hover:text-white" />
          </button>

        </div>

        <div className="grid grid-cols-2 gap-5">

          <input
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="Username"
          />

          <input
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="Email"
          />

          <input
            type="password"
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="Password"
          />

          <select className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white">
            <option>User</option>
            <option>Administrator</option>
          </select>

          <input
            type="number"
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="CPU Cores"
          />

          <input
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="RAM (GB)"
          />

          <input
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="Disk (GB)"
          />

          <input
            type="number"
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="Website Limit"
          />

          <input
            type="number"
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white"
            placeholder="Database Limit"
          />

          <select className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white">
            <option>Docker Enabled</option>
            <option>Docker Disabled</option>
          </select>

        </div>

        <div className="mt-8 flex justify-end gap-4">

          <button
            onClick={onClose}
            className="rounded-xl border border-slate-700 px-6 py-3 text-white"
          >
            Cancel
          </button>

          <button className="rounded-xl bg-blue-600 px-6 py-3 font-semibold text-white hover:bg-blue-700">
            Create User
          </button>

        </div>

      </div>

    </div>
  );
}