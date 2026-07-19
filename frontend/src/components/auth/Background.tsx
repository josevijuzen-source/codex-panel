import type { ReactNode } from "react";

interface Props {
  children: ReactNode;
}

export default function Background({ children }: Props) {
  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[#020817]">

      <div className="absolute left-20 top-40 h-72 w-72 rounded-full bg-blue-700/20 blur-[140px]" />

      <div className="absolute bottom-20 right-20 h-96 w-96 rounded-full bg-cyan-500/10 blur-[180px]" />

      {children}

    </div>
  );
}