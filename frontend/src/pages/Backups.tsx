import { useEffect, useState } from "react";
import axios from "axios";

interface Backup {
  id: string;
  name: string;
  size: string;
  createdAt: string;
  status: string;
}

export default function Backups() {
  const [backups, setBackups] = useState<Backup[]>([]);
  const [loading, setLoading] = useState(true);

  const [deleteId, setDeleteId] = useState<string | null>(null);

  const loadBackups = async () => {
    try {
      const res = await axios.get("http://localhost:5000/api/backups");
      setBackups(res.data.backups || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const createBackup = async () => {
    try {
      await axios.post("http://localhost:5000/api/backups/create");
      loadBackups();
    } catch (err) {
      console.error(err);
    }
  };

  const downloadBackup = (id: string) => {
    window.open(
      `http://localhost:5000/api/backups/download/${id}`,
      "_blank"
    );
  };

  const deleteBackup = async () => {
    if (!deleteId) return;

    try {
      await axios.delete(
        `http://localhost:5000/api/backups/${deleteId}`
      );

      setDeleteId(null);
      loadBackups();
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    loadBackups();
  }, []);

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold">Backups</h1>

        <button
          onClick={createBackup}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg"
        >
          + Create Backup
        </button>
      </div>

      {loading ? (
        <p>Loading backups...</p>
      ) : (
        <table className="w-full border rounded-lg overflow-hidden">
          <thead className="bg-gray-800 text-white">
            <tr>
              <th className="p-3 text-left">Name</th>
              <th className="p-3 text-left">Size</th>
              <th className="p-3 text-left">Created</th>
              <th className="p-3 text-left">Status</th>
              <th className="p-3 text-left">Actions</th>
            </tr>
          </thead>

          <tbody>
            {backups.length > 0 ? (
              backups.map((backup) => (
                <tr key={backup.id} className="border-b">
                  <td className="p-3">{backup.name}</td>

                  <td className="p-3">{backup.size}</td>

                  <td className="p-3">{backup.createdAt}</td>

                  <td className="p-3">
                    <span className="bg-green-100 text-green-700 px-2 py-1 rounded">
                      {backup.status}
                    </span>
                  </td>

                  <td className="p-3">
                    <div className="flex gap-2">
                      <button
                        onClick={() => downloadBackup(backup.id)}
                        className="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded"
                      >
                        Download
                      </button>

                      <button
                        onClick={() => setDeleteId(backup.id)}
                        className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td
                  colSpan={5}
                  className="text-center py-8 text-gray-500"
                >
                  No backups found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}

      {deleteId && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-96 p-6">
            <h2 className="text-xl font-bold mb-2">
              Delete Backup
            </h2>

            <p className="text-gray-600 mb-6">
              Are you sure you want to delete this backup?
            </p>

            <div className="flex justify-end gap-3">
              <button
                onClick={() => setDeleteId(null)}
                className="px-4 py-2 rounded bg-gray-300 hover:bg-gray-400"
              >
                Cancel
              </button>

              <button
                onClick={deleteBackup}
                className="px-4 py-2 rounded bg-red-600 hover:bg-red-700 text-white"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}