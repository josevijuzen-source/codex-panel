import {
  Database,
  Plus,
  Trash2,
  User,
  Key,
} from "lucide-react";
import { useEffect, useState } from "react";
import toast from "react-hot-toast";

import {
  getDatabases,
  createDatabase,
  deleteDatabase,
  updateDatabasePassword,
  type Database as DatabaseType,
} from "../api/databases";

export default function Databases() {
  const [databases, setDatabases] = useState<DatabaseType[]>([]);
  const [loading, setLoading] = useState(true);

  const [open, setOpen] = useState(false);

  const [name, setName] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const loadDatabases = async () => {
    try {
      setLoading(true);

      const data = await getDatabases();

      setDatabases(data);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load databases");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDatabases();
  }, []);

  const handleCreate = async () => {
    if (!name.trim() || !username.trim() || !password.trim()) {
      toast.error("Please fill all fields");
      return;
    }

    try {
      await createDatabase({
        name,
        username,
        password,
      });

      toast.success("Database created");

      setOpen(false);

      setName("");
      setUsername("");
      setPassword("");

      await loadDatabases();
    } catch (error) {
      console.error(error);
      toast.error("Failed to create database");
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Delete this database?")) return;

    try {
      await deleteDatabase(id);

      toast.success("Database deleted");

      await loadDatabases();
    } catch (error) {
      console.error(error);
      toast.error("Delete failed");
    }
  };

  const handlePassword = async (id: number) => {
    const newPassword = prompt("Enter new password");

    if (!newPassword) return;

    try {
      await updateDatabasePassword(id, newPassword);

      toast.success("Password updated");
    } catch (error) {
      console.error(error);
      toast.error("Password update failed");
    }
  };

  return (<div className="space-y-8">

  <div className="flex items-center justify-between">

    <div>

      <h1 className="text-4xl font-bold text-white">
        Databases
      </h1>

      <p className="text-slate-400">
        Manage MySQL / MariaDB databases
      </p>

    </div>

    <button
      onClick={() => setOpen(true)}
      className="flex items-center gap-2 rounded-xl bg-blue-600 px-5 py-3 text-white hover:bg-blue-700"
    >
      <Plus size={18} />
      Create Database
    </button>

  </div>

  <div className="overflow-hidden rounded-2xl border border-slate-700">

    <table className="w-full">

      <thead className="bg-slate-800">

        <tr>

          <th className="p-4 text-left">
            Database
          </th>

          <th>User</th>

          <th>Size</th>

          <th>Actions</th>

        </tr>

      </thead>

      <tbody>

        {loading ? (

          <tr>

            <td
              colSpan={4}
              className="p-8 text-center text-slate-400"
            >
              Loading databases...
            </td>

          </tr>

        ) : databases.length === 0 ? (

          <tr>

            <td
              colSpan={4}
              className="p-8 text-center text-slate-400"
            >
              No databases found.
            </td>

          </tr>

        ) : (

          databases.map((db) => (

            <tr
              key={db.id}
              className="border-t border-slate-700 hover:bg-slate-800"
            >

              <td className="flex items-center gap-3 p-4">

                <Database
                  className="text-blue-400"
                  size={20}
                />

                {db.name}

              </td>

              <td>

                <div className="flex items-center gap-2">

                  <User size={16} />

                  {db.username}

                </div>

              </td>

              <td>{db.size}</td>

              <td>

                <div className="flex gap-2">

                  <button
                    onClick={() => handlePassword(db.id)}
                    className="rounded bg-slate-700 p-2 hover:bg-slate-600"
                  >
                    <Key size={16} />
                  </button>

                  <button
                    onClick={() => handleDelete(db.id)}
                    className="rounded bg-red-600 p-2 hover:bg-red-700"
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
    {open && (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="w-[500px] rounded-2xl bg-slate-900 p-8">

        <h2 className="mb-6 text-2xl font-bold text-white">
          Create Database
        </h2>

        <div className="space-y-4">

          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Database Name"
            className="w-full rounded-lg bg-slate-800 p-3 text-white outline-none focus:ring-2 focus:ring-blue-500"
          />

          <input
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Username"
            className="w-full rounded-lg bg-slate-800 p-3 text-white outline-none focus:ring-2 focus:ring-blue-500"
          />

          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
            className="w-full rounded-lg bg-slate-800 p-3 text-white outline-none focus:ring-2 focus:ring-blue-500"
          />

          <div className="flex gap-3 pt-2">

            <button
              onClick={() => {
                setOpen(false);
                setName("");
                setUsername("");
                setPassword("");
              }}
              className="flex-1 rounded-lg bg-slate-700 py-3 text-white hover:bg-slate-600"
            >
              Cancel
            </button>

            <button
              onClick={handleCreate}
              className="flex-1 rounded-lg bg-blue-600 py-3 text-white hover:bg-blue-700"
            >
              Create Database
            </button>

          </div>

        </div>

      </div>
    </div>
  )}

</div>
  );
}