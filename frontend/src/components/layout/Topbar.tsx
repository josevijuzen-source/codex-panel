export default function Topbar() {
  return (
    <header className="flex h-16 items-center justify-between border-b border-slate-800 bg-slate-950 px-8">
      <h1 className="text-xl font-bold">Dashboard</h1>

      <div className="flex items-center gap-4">
        <button className="rounded-lg bg-slate-800 px-4 py-2 hover:bg-slate-700">
          Notifications
        </button>

        <div className="flex items-center gap-3">
          <div className="h-10 w-10 rounded-full bg-blue-600"></div>

          <div>
            <p className="font-semibold">Administrator</p>
            <p className="text-sm text-slate-400">
              admin@codexpanel.com
            </p>
          </div>
        </div>
      </div>
    </header>
  );
}