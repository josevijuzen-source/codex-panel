export default function FTP() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-4xl font-bold text-white">
          FTP Accounts
        </h1>

        <p className="text-slate-400">
          Create and manage FTP users for your websites.
        </p>
      </div>

      <div className="rounded-2xl border border-slate-700 bg-slate-900 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-white">
            FTP Accounts
          </h2>

          <button className="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700">
            + Create FTP Account
          </button>
        </div>

        <div className="overflow-hidden rounded-xl border border-slate-700">
          <table className="w-full">
            <thead className="bg-slate-800">
              <tr>
                <th className="p-4 text-left">Username</th>
                <th className="text-left">Website</th>
                <th className="text-left">Home Directory</th>
                <th className="text-left">Status</th>
                <th className="text-left">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr>
                <td
                  colSpan={5}
                  className="p-8 text-center text-slate-400"
                >
                  No FTP accounts found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}