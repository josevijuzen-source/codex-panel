import { X } from "lucide-react";

interface Props {
  open: boolean;
  fileName: string;
  newName: string;
  setNewName: (value: string) => void;
  onClose: () => void;
  onRename: () => void;
}

export default function RenameModal({
  open,
  fileName,
  newName,
  setNewName,
  onClose,
  onRename,
}: Props) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="w-[450px] rounded-2xl bg-slate-900 border border-slate-700 p-6">

        <div className="flex items-center justify-between mb-5">
          <h2 className="text-2xl font-bold text-white">
            Rename
          </h2>

          <button onClick={onClose}>
            <X />
          </button>
        </div>

        <p className="text-slate-400 mb-3">
          Current:
        </p>

        <div className="mb-5 rounded-lg bg-slate-800 p-3 text-white">
          {fileName}
        </div>

        <input
          value={newName}
          onChange={(e) =>
            setNewName(e.target.value)
          }
          placeholder="New file name"
          className="w-full rounded-lg bg-slate-800 border border-slate-700 p-3 text-white"
        />

        <div className="mt-6 flex justify-end gap-3">

          <button
            onClick={onClose}
            className="rounded-lg bg-slate-700 px-5 py-2 text-white"
          >
            Cancel
          </button>

          <button
            onClick={onRename}
            className="rounded-lg bg-blue-600 px-5 py-2 text-white"
          >
            Rename
          </button>

        </div>

      </div>
    </div>
  );
}