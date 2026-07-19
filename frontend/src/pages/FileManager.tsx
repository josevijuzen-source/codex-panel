import toast from "react-hot-toast";
import CreateFolderModal from "../components/filemanager/CreateFolderModal";
import DeleteConfirmModal from "../components/filemanager/DeleteConfirmModal";
import RenameModal from "../components/filemanager/RenameModal";
import UploadModal from "../components/filemanager/UploadModal";
import { useSearchParams } from "react-router-dom";

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

import { useEffect, useState } from "react";

import {
  getFiles,
  createFolder,
  deleteFile,
  downloadFile,
  renameFile,
} from "../api/files";



interface FileItem {
  name: string;
  isDirectory: boolean;
  size: number;
  modified: string;
}



export default function FileManager() {
  
const [searchParams] = useSearchParams();

const [search, setSearch] = useState("");





const websiteId = searchParams.get("website");

const [path, setPath] = useState("/");

  const [files, setFiles] = useState<FileItem[]>([]);
  const [loading, setLoading] = useState(true);

  const [showNewFolderModal, setShowNewFolderModal] = useState(false);
  const [folderName, setFolderName] = useState("");
  
  const [showDeleteModal, setShowDeleteModal] = useState(false);
   
const [showUploadModal, setShowUploadModal] = useState(false);


const [showRenameModal, setShowRenameModal] = useState(false);
const [selectedFile, setSelectedFile] = useState("");
const [newName, setNewName] = useState("");

  const handleNewFolder = () => {
    setShowNewFolderModal(true);
  };
  const createNewFolder = async () => {
  if (!folderName.trim()) return;


  try {
    await createFolder(path, folderName);

    toast.success("Folder created");

    await loadFiles();

    setFolderName("");
    setShowNewFolderModal(false);
  } catch (error) {
    console.error(error);
    toast.error("Failed to create folder");
  }
};



const handleDelete = (name: string) => {
  setSelectedFile(name);
  setShowDeleteModal(true);
};
const confirmDelete = async () => {
  try {
    await deleteFile(path, selectedFile);

    toast.success("Deleted successfully");

    await loadFiles();

    setShowDeleteModal(false);
    setSelectedFile("");
  } catch (error) {
    console.error(error);
    toast.error("Delete failed");
  }
};
const confirmRename = async () => {
  try {
    await renameFile(path, selectedFile, newName);

    toast.success("Renamed successfully");

    await loadFiles();

    setShowRenameModal(false);
    setSelectedFile("");
    setNewName("");
  } catch (error) {
    console.error(error);

    toast.error("Rename failed");
  }
};

  const loadFiles = async () => {
  try {
    const data = await getFiles(path, websiteId || "");
    setFiles(data.files);
  } catch (error) {
    console.error(error);
  } finally {
    setLoading(false);
  }
};

useEffect(() => {
  loadFiles();
}, [path, websiteId]);

  return (

<div className="space-y-6">

  <input
  type="text"
  placeholder="Search files..."
  value={search}
  onChange={(e) => setSearch(e.target.value)}
  className="mb-4 w-full rounded-lg bg-slate-800 p-3 text-white"
/>

    
      <div className="flex items-center justify-between">

        <div>

          <h1 className="text-4xl font-bold text-white">
            File Manager
          </h1>

          <p className="text-slate-400">
            {path}
          </p>

          <div className="mt-2 text-sm text-slate-500">
  {path.split("/").map((item, index) => (
    <span key={index}>
      {item || "Root"}
      {index < path.split("/").length - 1 && " / "}
    </span>
  ))}
</div>

        </div>

        <button
  onClick={() => {
    if (path === "/") return;

    const parent =
      path.substring(0, path.lastIndexOf("/")) || "/";

    setPath(parent);
  }}
  className="rounded-lg bg-slate-800 px-4 py-2 hover:bg-slate-700"
>
  Back
</button>

        <div className="flex gap-3">

          <button
            onClick={loadFiles}
            className="rounded-lg bg-slate-800 p-3 hover:bg-slate-700"
          >
            <RefreshCw
              className="text-white"
              size={18}
            />
          </button>

         <button
  onClick={() => setShowUploadModal(true)}
  className="rounded-lg bg-slate-800 p-3 hover:bg-slate-700"
>
  <Upload
    className="text-white"
    size={18}
  />
</button>

          <button
  onClick={handleNewFolder}
  className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
>
  <Plus size={18} />
  New Folder
</button>

        </div>

      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-700">

        <table className="w-full">

          <thead className="bg-slate-800">

            <tr>

              <th className="p-4 text-left">
                Name
              </th>

              <th>Type</th>

              <th>Size</th>

              <th>Modified</th>

              <th>Actions</th>

            </tr>

          </thead>

          <tbody>

            {loading ? (

              <tr>

                <td
                  colSpan={5}
                  className="p-8 text-center text-slate-400"
                >
                  Loading...
                </td>

              </tr>

            ) : files.length === 0 ? (

              <tr>

                <td
                  colSpan={5}
                  className="p-8 text-center text-slate-400"
                >
                  No files found.
                </td>

              </tr>

            ) : (

              files
  .filter((file) =>
    file.name.toLowerCase().includes(search.toLowerCase())
  )
  .map((file) => (
    <tr
      key={file.name}
      onDoubleClick={() => {
        if (!file.isDirectory) return;

        const newPath =
          path === "/"
            ? `/${file.name}`
            : `${path}/${file.name}`;

        setPath(newPath);
      }}
      className="cursor-pointer border-t border-slate-700 hover:bg-slate-800"
    >


                  <td className="flex items-center gap-3 p-4">

                    {file.isDirectory ? (
  <Folder
    className="text-yellow-400"
    size={20}
  />
) : file.name.endsWith(".zip") ? (
  <span className="text-xl">📦</span>
) : file.name.endsWith(".png") ||
  file.name.endsWith(".jpg") ||
  file.name.endsWith(".jpeg") ||
  file.name.endsWith(".gif") ? (
  <span className="text-xl">🖼️</span>
) : file.name.endsWith(".html") ? (
  <span className="text-xl">🌐</span>
) : file.name.endsWith(".css") ? (
  <span className="text-xl">🎨</span>
) : file.name.endsWith(".js") ||
  file.name.endsWith(".ts") ? (
  <span className="text-xl">📜</span>
) : file.name.endsWith(".php") ? (
  <span className="text-xl">🐘</span>
) : file.name.endsWith(".json") ? (
  <span className="text-xl">📝</span>
) : file.name.endsWith(".txt") ? (
  <span className="text-xl">📄</span>
) : (
  <File
    className="text-blue-400"
    size={20}
  />
)}

                    {file.name}

                  </td>

                  <td>
                    {file.isDirectory
                      ? "Folder"
                      : "File"}
                  </td>

                  <td>

                    {file.isDirectory
                      ? "--"
                      : `${Math.round(file.size / 1024)} KB`}

                  </td>

                  <td>
                    {new Date(file.modified).toLocaleString()}
                  </td>

                  <td>

                   <div className="flex gap-2">

  <button
  onClick={() => {
    setSelectedFile(file.name);
    setNewName(file.name);
    setShowRenameModal(true);
  }}
  className="rounded bg-slate-700 p-2 hover:bg-slate-600"
>
  <Edit size={16} />
</button>

  <button
    onClick={() =>
      downloadFile(`${path}/${file.name}`)
    }
    className="rounded bg-slate-700 p-2 hover:bg-slate-600"
  >
    <Download size={16} />
  </button>

                      <button
  onClick={() => handleDelete(file.name)}
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

      <CreateFolderModal
        open={showNewFolderModal}
        folderName={folderName}
        setFolderName={setFolderName}
        onClose={() => {
          setShowNewFolderModal(false);
          setFolderName("");
        }}
        onCreate={createNewFolder}
      />
<DeleteConfirmModal
  open={showDeleteModal}
  fileName={selectedFile}
  onClose={() => {
    setShowDeleteModal(false);
    setSelectedFile("");
  }}
  onDelete={confirmDelete}
/>
<UploadModal
  open={showUploadModal}
  onClose={() => setShowUploadModal(false)}
  onUploaded={loadFiles}
/>
<RenameModal
  open={showRenameModal}
  fileName={selectedFile}
  newName={newName}
  setNewName={setNewName}
  onClose={() => {
    setShowRenameModal(false);
    setSelectedFile("");
    setNewName("");
  }}
  onRename={confirmRename}
/>

    </div>
  );
}