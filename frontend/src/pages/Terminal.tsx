import { useState } from "react";
import { Terminal as TerminalIcon } from "lucide-react";
import toast from "react-hot-toast";
import { executeCommand } from "../api/terminal";



export default function Terminal() {
  const [command, setCommand] = useState("");

  const [history, setHistory] = useState<string[]>([
    "🚀 Welcome to Codex Panel Terminal",
    "Type a command and press Enter.",
    "",
  ]);

  const runCommand = async () => {
    if (!command.trim()) return;

    const currentCommand = command;

    setHistory((prev) => [
      ...prev,
      `root@codexpanel:~# ${currentCommand}`,
    ]);

    setCommand("");

    try {
      const data = await executeCommand(currentCommand);

      setHistory((prev) => [
        ...prev,
        data.output || "(no output)",
        "",
      ]);
    } catch (error) {
      console.error(error);

      toast.error("Command failed");

      setHistory((prev) => [
        ...prev,
        "❌ Failed to execute command.",
        "",
      ]);
    }
  };

  return (
    <div className="space-y-6">

      <div className="flex items-center gap-3">

        <TerminalIcon
          className="text-green-400"
          size={32}
        />

        <h1 className="text-4xl font-bold text-white">
          Browser Terminal
        </h1>

      </div>

      <div className="h-[600px] overflow-y-auto rounded-2xl border border-slate-700 bg-black p-6 font-mono text-green-400">

        {history.map((line, index) => (
          <div
            key={index}
            className="whitespace-pre-wrap"
          >
            {line}
          </div>
        ))}

      </div>

      <div className="flex gap-3">

        <input
          value={command}
          onChange={(e) => setCommand(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") runCommand();
          }}
          placeholder="Enter command..."
          className="flex-1 rounded-lg bg-slate-800 p-3 text-white outline-none"
        />

        <button
          onClick={runCommand}
          className="rounded-lg bg-green-600 px-6 py-3 text-white hover:bg-green-700"
        >
          Run
        </button>

      </div>

    </div>
  );
}