import { ShieldCheck, Lock, RefreshCw, Trash2 } from "lucide-react";

export default function SSL() {
  return (
    <div className="space-y-6">

      <div>
        <h1 className="text-4xl font-bold text-white">
          SSL Certificates
        </h1>

        <p className="mt-2 text-slate-400">
          Manage Let's Encrypt SSL certificates for your websites.
        </p>
      </div>

      <div className="rounded-2xl border border-slate-700 bg-slate-900 p-6">

        <h2 className="mb-5 text-2xl font-bold text-white">
          Generate SSL
        </h2>

        <div className="grid gap-4 md:grid-cols-2">

          <input
            type="text"
            placeholder="example.com"
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white outline-none"
          />

          <input
            type="email"
            placeholder="admin@example.com"
            className="rounded-xl border border-slate-700 bg-slate-800 p-3 text-white outline-none"
          />

        </div>

        <button
          className="mt-6 flex items-center gap-2 rounded-xl bg-green-600 px-6 py-3 text-white hover:bg-green-700"
        >
          <ShieldCheck size={18} />
          Generate SSL
        </button>

      </div>

      <div className="rounded-2xl border border-slate-700 overflow-hidden">

        <table className="w-full">

          <thead className="bg-slate-800">

            <tr>

              <th className="p-4 text-left">Domain</th>

              <th>Status</th>

              <th>Expires</th>

              <th>Actions</th>

            </tr>

          </thead>

          <tbody>

            <tr className="border-t border-slate-700 hover:bg-slate-800">

              <td className="p-4">
                example.com
              </td>

              <td className="text-green-400">
                Active
              </td>

              <td>
                90 Days
              </td>

              <td>

                <div className="flex gap-2">

                  <button className="rounded bg-blue-600 p-2 hover:bg-blue-700">
                    <RefreshCw size={16} />
                  </button>

                  <button className="rounded bg-yellow-600 p-2 hover:bg-yellow-700">
                    <Lock size={16} />
                  </button>

                  <button className="rounded bg-red-600 p-2 hover:bg-red-700">
                    <Trash2 size={16} />
                  </button>

                </div>

              </td>

            </tr>

          </tbody>

        </table>

      </div>

    </div>
  );
}