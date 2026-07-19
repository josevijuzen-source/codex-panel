import { X } from "lucide-react";

interface Props {
  open: boolean;
  folderName: string;
  setFolderName: (value: string) => void;
  onClose: () => void;
  onCreate: () => void;
}

export default function CreateFolderModal({
  open,
  folderName,
  setFolderName,
  onClose,
  onCreate,
}: Props) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="w-[450px] rounded-2xl border border-slate-700 bg-slate-900 p-6">
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-white">
            Create Folder
          </h2>

          <button onClick={onClose}>
            <X className="text-slate-400 hover:text-white" />
          </button>
        </div>

        <input
          autoFocus
          value={folderName}
          onChange={(e) => setFolderName(e.target.value)}
          placeholder="Folder name"
          className="mb-6 w-full rounded-xl border border-slate-700 bg-slate-800 p-3 text-white outline-none"
        />

        <div className="flex justify-end gap-3">
          <button
            onClick={onClose}
            className="rounded-lg bg-slate-700 px-5 py-2 text-white"
          >
            Cancel
          </button>

          <button
            onClick={onCreate}
            className="rounded-lg bg-blue-600 px-5 py-2 text-white hover:bg-blue-700"
          >
            Create
          </button>
        </div>
      </div>
    </div>
  );
}