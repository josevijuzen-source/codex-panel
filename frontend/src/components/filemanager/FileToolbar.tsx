import { Search, Upload, FolderPlus, FilePlus, RefreshCw } from "lucide-react";

interface Props {
  search: string;
  onSearch: (value: string) => void;
  onUpload: () => void;
  onNewFolder: () => void;
  onNewFile: () => void;
  onRefresh: () => void;
}

export default function FileToolbar({
  search,
  onSearch,
  onUpload,
  onNewFolder,
  onNewFile,
  onRefresh,
}: Props) {
  return (
    <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">

      <div className="relative w-full lg:max-w-md">
        <Search
          size={18}
          className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
        />

        <input
          value={search}
          onChange={(e) => onSearch(e.target.value)}
          placeholder="Search files..."
          className="w-full rounded-xl border border-slate-700 bg-slate-800 py-3 pl-10 pr-4 text-white outline-none focus:border-blue-500"
        />
      </div>

      <div className="flex flex-wrap gap-3">

        <button
          onClick={onUpload}
          className="flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-3 text-white hover:bg-blue-700"
        >
          <Upload size={18} />
          Upload
        </button>

        <button
          onClick={onNewFolder}
          className="flex items-center gap-2 rounded-xl bg-green-600 px-4 py-3 text-white hover:bg-green-700"
        >
          <FolderPlus size={18} />
          Folder
        </button>

        <button
          onClick={onNewFile}
          className="flex items-center gap-2 rounded-xl bg-purple-600 px-4 py-3 text-white hover:bg-purple-700"
        >
          <FilePlus size={18} />
          File
        </button>

        <button
          onClick={onRefresh}
          className="flex items-center gap-2 rounded-xl bg-slate-700 px-4 py-3 text-white hover:bg-slate-600"
        >
          <RefreshCw size={18} />
          Refresh
        </button>

      </div>
    </div>
  );
}