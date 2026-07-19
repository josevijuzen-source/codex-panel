export default function Domains() {
  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-4xl font-bold text-white">
            Domains
          </h1>

          <p className="text-slate-400">
            Manage domains and subdomains.
          </p>
        </div>

        <button className="rounded-xl bg-blue-600 px-5 py-3 text-white hover:bg-blue-700">
          + Add Domain
        </button>
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-700">

        <table className="w-full">

          <thead className="bg-slate-800">

            <tr>

              <th className="p-4 text-left">
                Domain
              </th>

              <th>Status</th>

              <th>SSL</th>

              <th>Website</th>

              <th>Actions</th>

            </tr>

          </thead>

          <tbody>

            <tr>

              <td
                colSpan={5}
                className="p-10 text-center text-slate-400"
              >
                No domains found.
              </td>

            </tr>

          </tbody>

        </table>

      </div>

    </div>
  );
}