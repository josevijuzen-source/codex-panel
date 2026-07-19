import { X, Trash2 } from "lucide-react";

interface Props {
  open: boolean;
  fileName: string;
  onClose: () => void;
  onDelete: () => void;
}

export default function DeleteConfirmModal({
  open,
  fileName,
  onClose,
  onDelete,
}: Props) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="w-[450px] rounded-2xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">

        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-white">
            Delete File
          </h2>

          <button onClick={onClose}>
            <X className="text-slate-400 hover:text-white" />
          </button>
        </div>

        <p className="mb-6 text-slate-300">
          Are you sure you want to delete
          <span className="font-semibold text-red-400">
            {" "}
            {fileName}
          </span>
          ?
        </p>

        <div className="flex justify-end gap-3">
          <button
            onClick={onClose}
            className="rounded-lg bg-slate-700 px-5 py-2 text-white hover:bg-slate-600"
          >
            Cancel
          </button>

          <button
            onClick={onDelete}
            className="flex items-center gap-2 rounded-lg bg-red-600 px-5 py-2 text-white hover:bg-red-700"
          >
            <Trash2 size={18} />
            Delete
          </button>
        </div>

      </div>
    </div>
  );
}