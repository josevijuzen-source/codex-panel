import { useState } from "react";
import { installWordPress } from "../api/wordpress";

export default function WordPress() {
  const [websiteId, setWebsiteId] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleInstall() {
    if (!websiteId) {
      alert("Enter Website ID");
      return;
    }

    try {
      setLoading(true);

      const result = await installWordPress({
        websiteId: Number(websiteId),
      });

      alert(result.message);
    } catch (err: any) {
      alert(
        err?.response?.data?.message ??
          "Installation failed."
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">
        WordPress Installer
      </h1>

      <div className="rounded-xl bg-slate-900 p-6 space-y-4">

        <input
          type="number"
          placeholder="Website ID"
          value={websiteId}
          onChange={(e) =>
            setWebsiteId(e.target.value)
          }
          className="w-full rounded-lg border border-slate-700 bg-slate-800 p-3 text-white"
        />

        <button
          onClick={handleInstall}
          disabled={loading}
          className="rounded-lg bg-blue-600 px-5 py-3 text-white hover:bg-blue-700"
        >
          {loading
            ? "Installing..."
            : "Install WordPress"}
        </button>

      </div>
    </div>
  );
}