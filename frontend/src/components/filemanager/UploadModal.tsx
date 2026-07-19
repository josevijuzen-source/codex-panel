import { X, Upload } from "lucide-react";
import { useRef, useState } from "react";
import toast from "react-hot-toast";

interface Props {
  open: boolean;
  onClose: () => void;
  onUploaded: () => void;
}

export default function UploadModal({
  open,
  onClose,
  onUploaded,
}: Props) {
  const inputRef = useRef<HTMLInputElement>(null);

  const [loading, setLoading] = useState(false);

  if (!open) return null;

  const handleUpload = async (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = e.target.files?.[0];

    if (!file) return;

    try {
      setLoading(true);

      const form = new FormData();

      form.append("file", file);
      form.append("path", ".");

      await fetch("http://localhost:5000/api/upload", {
        method: "POST",
        body: form,
      });

      toast.success("File uploaded");

      onUploaded();

      onClose();
    } catch (err) {
      console.error(err);
      toast.error("Upload failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">

      <div className="w-[500px] rounded-2xl border border-slate-700 bg-slate-900 p-6">

        <div className="mb-6 flex items-center justify-between">

          <h2 className="text-2xl font-bold text-white">
            Upload File
          </h2>

          <button onClick={onClose}>
            <X className="text-slate-400 hover:text-white" />
          </button>

        </div>

        <div
          onClick={() => inputRef.current?.click()}
          className="cursor-pointer rounded-xl border-2 border-dashed border-slate-600 p-12 text-center hover:border-blue-500"
        >

          <Upload
            className="mx-auto mb-4 text-blue-400"
            size={50}
          />

          <p className="text-lg text-white">
            Click to choose a file
          </p>

          <p className="mt-2 text-slate-400">
            Upload any file
          </p>

        </div>

        <input
          ref={inputRef}
          hidden
          type="file"
          onChange={handleUpload}
        />

        {loading && (
          <p className="mt-4 text-center text-blue-400">
            Uploading...
          </p>
        )}

      </div>

    </div>
  );
}