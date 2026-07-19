import {
  FolderOpen,
  Edit,
 Download,
  Copy,
  Scissors,
  ClipboardPaste,
  Archive,
  PackageOpen,
  Trash2,
  Info,
} from "lucide-react";

interface Props {
  x: number;
  y: number;
  visible: boolean;
  isDirectory: boolean;

  onOpen: () => void;
  onRename: () => void;
  onDownload: () => void;
  onCopy: () => void;
  onCut: () => void;
  onPaste: () => void;
  onCompress: () => void;
  onExtract: () => void;
  onDelete: () => void;
  onProperties: () => void;
}

export default function FileContextMenu({
  x,
  y,
  visible,
  isDirectory,
  onOpen,
  onRename,
  onDownload,
  onCopy,
  onCut,
  onPaste,
  onCompress,
  onExtract,
  onDelete,
  onProperties,
}: Props) {
  if (!visible) return null;

  const MenuButton = ({
    icon,
    label,
    onClick,
    danger = false,
  }: {
    icon: React.ReactNode;
    label: string;
    onClick: () => void;
    danger?: boolean;
  }) => (
    <button
      onClick={onClick}
      className={`flex w-full items-center gap-3 px-4 py-2 text-left transition ${
        danger
          ? "text-red-400 hover:bg-red-600/20"
          : "text-slate-200 hover:bg-slate-700"
      }`}
    >
      {icon}
      <span>{label}</span>
    </button>
  );

  return (
    <div
      className="fixed z-50 w-64 overflow-hidden rounded-xl border border-slate-700 bg-slate-900 shadow-2xl"
      style={{
        top: y,
        left: x,
      }}
    >
      <MenuButton
        icon={<FolderOpen size={18} />}
        label={isDirectory ? "Open Folder" : "Open File"}
        onClick={onOpen}
      />

      <MenuButton
        icon={<Edit size={18} />}
        label="Rename"
        onClick={onRename}
      />

      {!isDirectory && (
        <MenuButton
          icon={<Download size={18} />}
          label="Download"
          onClick={onDownload}
        />
      )}

      <hr className="border-slate-700" />

      <MenuButton
        icon={<Copy size={18} />}
        label="Copy"
        onClick={onCopy}
      />

      <MenuButton
        icon={<Scissors size={18} />}
        label="Cut"
        onClick={onCut}
      />

      <MenuButton
        icon={<ClipboardPaste size={18} />}
        label="Paste"
        onClick={onPaste}
      />

      <hr className="border-slate-700" />

      <MenuButton
        icon={<Archive size={18} />}
        label="Compress"
        onClick={onCompress}
      />

      {!isDirectory && (
        <MenuButton
          icon={<PackageOpen size={18} />}
          label="Extract ZIP"
          onClick={onExtract}
        />
      )}

      <hr className="border-slate-700" />

      <MenuButton
        icon={<Info size={18} />}
        label="Properties"
        onClick={onProperties}
      />

      <MenuButton
        icon={<Trash2 size={18} />}
        label="Delete"
        danger
        onClick={onDelete}
      />
    </div>
  );
}