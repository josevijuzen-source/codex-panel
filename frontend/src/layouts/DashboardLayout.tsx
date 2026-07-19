import Sidebar from "../components/layout/Sidebar";
import Topbar from "../components/layout/Topbar";

interface Props {
  children: React.ReactNode;
}

export default function DashboardLayout({ children }: Props) {
  return (
    <div className="flex h-screen bg-slate-950 text-white">
      <Sidebar />

      <div className="flex flex-1 flex-col overflow-hidden">
        <Topbar />

        <main className="flex-1 overflow-auto bg-slate-900 p-8">
          {children}
        </main>
      </div>
    </div>
  );
}