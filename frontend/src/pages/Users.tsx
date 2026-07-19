import { useState } from "react";
import CreateUserModal from "../components/users/CreateUserModal";

interface User {
  id: number;
  name: string;
  email: string;
  plan: string;
  cpu: number;
  ram: string;
  disk: string;
  websites: number;
  status: string;
}

const users: User[] = [
  {
    id: 1,
    name: "Aashiq",
    email: "admin@codexpanel.com",
    plan: "Pro",
    cpu: 8,
    ram: "16 GB",
    disk: "500 GB",
    websites: 100,
    status: "Active",
  },
  {
    id: 2,
    name: "John",
    email: "john@gmail.com",
    plan: "Basic",
    cpu: 2,
    ram: "4 GB",
    disk: "50 GB",
    websites: 5,
    status: "Active",
  },
];

export default function Users() {
  const [open, setOpen] = useState(false);

  return (
    <div>
      <CreateUserModal
        open={open}
        onClose={() => setOpen(false)}
      />

      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-4xl font-bold text-white">
            Users
          </h1>

          <p className="text-slate-400">
            Manage hosting users
          </p>
        </div>

        <button
          onClick={() => setOpen(true)}
          className="rounded-xl bg-blue-600 px-5 py-3 font-semibold text-white hover:bg-blue-700"
        >
          + Create User
        </button>
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-700">

        <table className="w-full">

          <thead className="bg-slate-800">

            <tr>

              <th className="p-4 text-left">Name</th>
              <th>Email</th>
              <th>Plan</th>
              <th>CPU</th>
              <th>RAM</th>
              <th>Disk</th>
              <th>Websites</th>
              <th>Status</th>

            </tr>

          </thead>

          <tbody>

            {users.map((user) => (

              <tr
                key={user.id}
                className="border-t border-slate-700 hover:bg-slate-800"
              >

                <td className="p-4">{user.name}</td>
                <td>{user.email}</td>
                <td>{user.plan}</td>
                <td>{user.cpu} Cores</td>
                <td>{user.ram}</td>
                <td>{user.disk}</td>
                <td>{user.websites}</td>

                <td>
                  <span className="rounded-full bg-green-600 px-3 py-1 text-sm text-white">
                    {user.status}
                  </span>
                </td>

              </tr>

            ))}

          </tbody>

        </table>

      </div>

    </div>
  );
}