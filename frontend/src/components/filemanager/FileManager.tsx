import { useState } from "react";
import {
  Folder,
  File,
  Upload,
  Download,
  Trash2,
  Edit,
  RefreshCw,
  Plus,
} from "lucide-react";

const files = [
  { name: "index.html", type: "file", size: "3 KB" },
  { name: "style.css", type: "file", size: "5 KB" },
  { name: "script.js", type: "file", size: "7 KB" },
  { name: "assets", type: "folder", size: "--" },
  { name: "images", type: "folder", size: "--" },
];

export default function FileManager() {
  const [currentPath] = useState("/var/www/codexpanel.com");

  return (
    <div className="space-y-6">

      <div className="flex items-center justify-between">

        <div>
          <h2 className="text-3xl font-bold text-white">
            File Manager
          </h2>

          <p className="text-slate-400">
            {currentPath}
          </p>
        </div>

        <div className="flex gap-3">

          <button className="rounded-lg bg-slate-800 p-3 text-white hover:bg-slate-700">
            <RefreshCw size={18} />
          </button>

          <button className="rounded-lg bg-slate-800 p-3 text-white hover:bg-slate-700">
            <Upload size={18} />
          </button>

          <button className="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 flex items-center gap-2">
            <Plus size={18} />
            New Folder
          </button>

        </div>

      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-700">

        <table className="w-full">

          <thead className="bg-slate-800">

            <tr>
              <th className="p-4 text-left">Name</th>
              <th>Size</th>
              <th>Actions</th>
            </tr>

          </thead>

          <tbody>

            {files.map((item) => (

              <tr
                key={item.name}
                className="border-t border-slate-700 hover:bg-slate-800"
              >

                <td className="flex items-center gap-3 p-4">

                  {item.type === "folder" ? (
                    <Folder className="text-yellow-400" size={20} />
                  ) : (
                    <File className="text-sky-400" size={20} />
                  )}

                  {item.name}

                </td>

                <td>{item.size}</td>

                <td>

                  <div className="flex gap-2">

                    <button className="rounded bg-slate-700 p-2 hover:bg-slate-600">
                      <Edit size={16} />
                    </button>

                    <button className="rounded bg-slate-700 p-2 hover:bg-slate-600">
                      <Download size={16} />
                    </button>

                    <button className="rounded bg-red-600 p-2 hover:bg-red-700">
                      <Trash2 size={16} />
                    </button>

                  </div>

                </td>

              </tr>

            ))}

          </tbody>

        </table>

      </div>

    </div>
  );
}